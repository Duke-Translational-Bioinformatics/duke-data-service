require 'rails_helper'

RSpec.describe ElasticsearchHandler do
  let(:verbose_subject) { described_class.new(verbose: true) }
  it {
    expect(ElasticsearchHandler.new.verbose).to be_falsey
    expect(ElasticsearchHandler.new.has_errors).to be_falsey
    expect(ElasticsearchHandler.new(verbose: true).verbose).to be_truthy
  }

  describe "#create_indices" do
    it { is_expected.to respond_to(:create_indices).with(0).arguments }
    it { is_expected.to respond_to(:create_indices).with(1).arguments }

    context 'nil client' do
      it {
        client = Elasticsearch::Model.client
        FolderFilesResponse.indexed_models.each do |indexed_model|
          expect(client.indices.exists? index: indexed_model.versioned_index_name).to be_falsey
          expect(client.indices.exists_alias? name: indexed_model.index_name).to be_falsey
        end

        subject.create_indices

        FolderFilesResponse.indexed_models.each do |indexed_model|
          expect(client.indices.exists? index: indexed_model.versioned_index_name).to be_truthy
          expect(client.indices.exists_alias? name: indexed_model.index_name).to be_truthy
          alias_info = client.indices.get_alias index: indexed_model.versioned_index_name
          expect(alias_info[indexed_model.versioned_index_name]["aliases"]).to have_key indexed_model.index_name
        end
      }
    end

    context 'client not nil' do
      let(:other_client) { Elasticsearch::Client.new url: ENV['BONSAI_URL'] }

      it {
        subject.drop_indices(other_client)
        FolderFilesResponse.indexed_models.each do |indexed_model|
          expect(other_client.indices.exists? index: indexed_model.versioned_index_name).to be_falsey
          expect(other_client.indices.exists_alias? name: indexed_model.index_name).to be_falsey
        end

        subject.create_indices(other_client)

        FolderFilesResponse.indexed_models.each do |indexed_model|
          expect(other_client.indices.exists? index: indexed_model.versioned_index_name).to be_truthy
          expect(other_client.indices.exists_alias? name: indexed_model.index_name).to be_truthy
          alias_info = other_client.indices.get_alias index: indexed_model.versioned_index_name
          expect(alias_info[indexed_model.versioned_index_name]["aliases"]).to have_key indexed_model.index_name
        end
        subject.drop_indices(other_client)
      }
    end
  end

  describe "#index_documents" do
    let(:indexed_data_file) { FactoryBot.create(:data_file) }
    let(:indexed_folder) { FactoryBot.create(:folder) }
    it { is_expected.to respond_to(:index_documents) }

    context 'with existing documents not already indexed' do
      include_context 'elasticsearch prep', [:indexed_data_file, :indexed_folder], []
      let(:client) { Elasticsearch::Model.client }
      before(:example) do
        expect(DataFile.__elasticsearch__.search(indexed_data_file.name).count).to eq 0
        expect(Folder.__elasticsearch__.search(indexed_folder.name).count).to eq 0
      end

      it {
        subject.index_documents

        client.indices.flush
        expect(DataFile.__elasticsearch__.search(indexed_data_file.name).count).to eq 1
        expect(Folder.__elasticsearch__.search(indexed_folder.name).count).to eq 1
      }
      context 'in verbose mode' do
        subject { verbose_subject }
        it { expect { subject.index_documents( client ) }.not_to output(/ids not loaded after 5 tries:/i).to_stderr }
        it { expect { subject.index_documents }.to output(/^\+\+$/).to_stderr }
      end

      context 'when bulk fails' do
        let(:fail_count) { 1 }
        before(:example) do
          expect(client).to receive(:bulk).exactly(fail_count) do |body:|
            results = {"index" => { "result" => "not_found", "status" => 404 } }
            items = body.map {|i| i.deep_stringify_keys.deep_merge(results) }
            { "errors" => true, "items" => items }
          end
        end
        context '... one time' do
          before(:example) do
            expect(client).to receive(:bulk).twice.and_call_original
          end
          it 'retries bulk job' do
            subject.index_documents( client )

            client.indices.flush
            expect(DataFile.__elasticsearch__.search(indexed_data_file.name).count).to eq 1
            expect(Folder.__elasticsearch__.search(indexed_folder.name).count).to eq 1
          end
          context 'in verbose mode' do
            subject { verbose_subject }
            it { expect { subject.index_documents( client ) }.not_to output(/ids not loaded after 5 tries:/i).to_stderr }
            it { expect { subject.index_documents( client ) }.to output(/^\+\+$/).to_stderr }
          end
        end

        context '... 5 times' do
          let(:fail_count) { 5 }
          before(:example) do
            expect(client).to receive(:bulk).once.and_call_original
          end
          it 'skips 1 bulk job' do
            subject.index_documents( client )

            client.indices.flush
            expect(DataFile.__elasticsearch__.search(indexed_data_file.name).count).to eq 0
            expect(Folder.__elasticsearch__.search(indexed_folder.name).count).to eq 1
          end
          context 'in verbose mode' do
            subject { verbose_subject }
            it { expect { subject.index_documents( client ) }.to output(/ids not loaded after 5 tries:/i).to_stderr }
            it { expect { subject.index_documents( client ) }.not_to output(/(.*ids not loaded after 5 tries:){2}/im).to_stderr }
            it { expect { subject.index_documents( client ) }.to output(/\n\+$/).to_stderr }
          end
        end

        context '... 10 times' do
          let(:fail_count) { 10 }
          it 'skips both bulk jobs' do
            subject.index_documents( client )

            client.indices.flush
            expect(DataFile.__elasticsearch__.search(indexed_data_file.name).count).to eq 0
            expect(Folder.__elasticsearch__.search(indexed_folder.name).count).to eq 0
          end
          context 'in verbose mode' do
            subject { verbose_subject }
            it { expect { subject.index_documents( client ) }.to output(/(.*ids not loaded after 5 tries:){2}/im).to_stderr }
            it { expect { subject.index_documents( client ) }.not_to output('\+').to_stderr }
          end
        end
      end
    end

    describe 'with existing documents indexed already' do
      include_context 'elasticsearch prep', [], [:indexed_data_file, :indexed_folder]

      it {
        expect(DataFile.__elasticsearch__.search(indexed_data_file.name).count).to eq 1
        expect(Folder.__elasticsearch__.search(indexed_folder.name).count).to eq 1
        subject.index_documents
        expect(DataFile.__elasticsearch__.search(indexed_data_file.name).count).to eq 1
        expect(Folder.__elasticsearch__.search(indexed_folder.name).count).to eq 1
      }
    end
  end

  describe "#drop_indices" do
    it { is_expected.to respond_to(:drop_indices).with(0).arguments }
    it { is_expected.to respond_to(:drop_indices).with(1).arguments }

    context 'nil client' do
      let(:indexed_data_file) { FactoryBot.create(:data_file) }
      let(:indexed_folder) { FactoryBot.create(:folder) }
      include_context 'elasticsearch prep', [:indexed_data_file, :indexed_folder], []

      it {
        client = Elasticsearch::Model.client
        FolderFilesResponse.indexed_models.each do |indexed_model|
          expect(client.indices.exists? index: indexed_model.versioned_index_name).to be_truthy
          expect(client.indices.exists_alias? name: indexed_model.index_name).to be_truthy
        end
        subject.drop_indices
        client.indices.flush
        FolderFilesResponse.indexed_models.each do |indexed_model|
          expect(client.indices.exists? index: indexed_model.versioned_index_name).to be_falsey
          expect(client.indices.exists_alias? name: indexed_model.index_name).to be_falsey
        end
      }
    end

    context 'client not nil' do
      let(:other_client) { Elasticsearch::Client.new url: ENV['BONSAI_URL'] }

      it {
        subject.create_indices(other_client)
        other_client.indices.flush
        FolderFilesResponse.indexed_models.each do |indexed_model|
          expect(other_client.indices.exists? index: indexed_model.versioned_index_name).to be_truthy
          expect(other_client.indices.exists_alias? name: indexed_model.index_name).to be_truthy
        end

        subject.drop_indices(other_client)

        other_client.indices.flush
        FolderFilesResponse.indexed_models.each do |indexed_model|
          expect(other_client.indices.exists? index: indexed_model.versioned_index_name).to be_falsey
          expect(other_client.indices.exists_alias? name: indexed_model.index_name).to be_falsey
        end
      }
    end
  end

  describe '#smart_reindex_indices' do
    it { is_expected.to respond_to :smart_reindex_indices }

    context 'versioned_index_name exists' do
      let(:indexed_data_file) { FactoryBot.create(:data_file) }
      let(:indexed_folder) { FactoryBot.create(:folder) }
      include_context 'elasticsearch prep', [], [:indexed_data_file, :indexed_folder]

      it {
        info = subject.smart_reindex_indices
        FolderFilesResponse.indexed_models.each do |indexed_model|
          expect(info[:skipped]).to include indexed_model.versioned_index_name
        end
      }
    end

    context 'versioned_index_name does not exist' do
      context 'index_name alias does not exist' do
        it {
          FolderFilesResponse.indexed_models.each do |indexed_model|
            expect(Elasticsearch::Model.client.indices.exists_alias? name: indexed_model.index_name).to be_falsey
          end

          info = subject.smart_reindex_indices

          FolderFilesResponse.indexed_models.each do |indexed_model|
            expect(info[:missing_aliases]).to include indexed_model.index_name
          end
        }
      end

      context 'index_name aliased to previous versioned_index_name with same migration_version' do
        let(:test_model) { DataFile }
        let(:test_model_previous_version) { "#{test_model.index_name}_#{SecureRandom.uuid}_#{test_model.migration_version}" }

        around :each do |example|
          client = Elasticsearch::Model.client
          client.indices.delete index: '_all'
          FolderFilesResponse.indexed_models.each do |indexed_model|
            previous_version = ("#{indexed_model}" == "#{test_model}") ? test_model_previous_version : indexed_model.versioned_index_name
            client.indices.create(
              index: previous_version,
              body: {
                settings: indexed_model.settings.to_hash,
                mappings: indexed_model.mappings.to_hash
              }
            )
            client.indices.put_alias index: previous_version, name: indexed_model.index_name
          end
          client.indices.flush

          data_file = FactoryBot.create(:data_file)
          data_file.__elasticsearch__.index_document
          folder = FactoryBot.create(:folder)
          folder.__elasticsearch__.index_document

          FolderFilesResponse.indexed_models.each do |indexed_model|
            indexed_model.__elasticsearch__.refresh_index!
          end

          example.run

          client.indices.delete index: '_all'
        end

        context 'without errors' do
          it {
            client = Elasticsearch::Model.client
            expect(test_model_previous_version).to match test_model.migration_version
            expect(client.indices.exists index: test_model_previous_version).to be_truthy
            expect(client.indices.exists index: test_model.versioned_index_name).to be_falsey
            expect(client.indices.exists_alias? name: test_model.index_name)
            existing_alias_info = client.indices.get_alias name: test_model.index_name
            expect(existing_alias_info[test_model_previous_version]["aliases"]).to have_key test_model.index_name

            info = subject.smart_reindex_indices

            expect(client.indices.exists index: test_model_previous_version).to be_falsey
            expect(client.indices.exists index: test_model.versioned_index_name).to be_truthy
            expect(client.indices.exists_alias? name: test_model.index_name)
            existing_alias_info = client.indices.get_alias name: test_model.index_name
            expect(existing_alias_info[test_model.versioned_index_name]["aliases"]).to have_key test_model.index_name

            expect(subject.has_errors).to be_falsey
            expect(info[:reindexed]).to have_key "#{test_model}"
            expect(info[:reindexed]["#{test_model}"][:from]).to eq test_model_previous_version
            expect(info[:reindexed]["#{test_model}"][:to]).to eq test_model.versioned_index_name
          }
        end

        context 'with errors' do
          let(:first_scroll_id) { SecureRandom.hex }
          let(:expected_first_response) {{
            '_scroll_id' => first_scroll_id,
            'hits' => {
              'hits' => [
                {'id' => SecureRandom.uuid }
              ]
            }
          }}
          let(:expected_first_batch) {{}}
          let(:first_batch_response) {{
            "errors" => true,
            "items" => [
              {"index" => { "status" => 403, "_id" => SecureRandom.uuid }}
            ]
          }}
          let(:empty_response) {{
            'hits' => {
              'hits' => []
            }
          }}

          it {
            client = Elasticsearch::Model.client
            expect(test_model_previous_version).to match test_model.migration_version
            expect(client.indices.exists index: test_model_previous_version).to be_truthy
            expect(client.indices.exists index: test_model.versioned_index_name).to be_falsey
            expect(client.indices.exists_alias? name: test_model.index_name)
            existing_alias_info = client.indices.get_alias name: test_model.index_name
            expect(existing_alias_info[test_model_previous_version]["aliases"]).to have_key test_model.index_name

            is_expected.to receive(:fast_reindex)
              .with(client, test_model_previous_version, client, test_model.versioned_index_name, false)
              .and_call_original.ordered

            is_expected.to receive(:start_scroll)
              .with(client, test_model_previous_version)
              .and_return(expected_first_response).ordered

            is_expected.to receive(:batch_from_search)
              .with(test_model.versioned_index_name, expected_first_response)
              .and_return(expected_first_batch).ordered

            is_expected.to receive(:send_batch)
              .with(client, expected_first_batch)
              .and_return(first_batch_response).ordered

            is_expected.to receive(:next_scroll)
              .with(client)
              .and_return(empty_response).ordered

            info = subject.smart_reindex_indices

            expect(subject.has_errors).to be_truthy
            expect(client.indices.exists index: test_model_previous_version).to be_truthy
            expect(client.indices.exists index: test_model.versioned_index_name).to be_truthy
            expect(client.indices.exists_alias? name: test_model.index_name).to be_truthy
            existing_alias_info = client.indices.get_alias name: test_model.index_name
            expect(existing_alias_info[test_model_previous_version]["aliases"]).to have_key test_model.index_name
            expect(existing_alias_info).not_to have_key test_model.versioned_index_name

            expect(info[:has_errors]).to include "#{test_model}"
          }
        end

        context 'with Elasticsearch::Transport::Transport::Errors::GatewayTimeout' do
          it {
            client = Elasticsearch::Model.client
            expect(test_model_previous_version).to match test_model.migration_version
            expect(client.indices.exists index: test_model_previous_version).to be_truthy
            expect(client.indices.exists index: test_model.versioned_index_name).to be_falsey
            expect(client.indices.exists_alias? name: test_model.index_name)
            existing_alias_info = client.indices.get_alias name: test_model.index_name
            expect(existing_alias_info[test_model_previous_version]["aliases"]).to have_key test_model.index_name

            is_expected.to receive(:fast_reindex)
              .with(client, test_model_previous_version, client, test_model.versioned_index_name, false)
              .and_raise(Elasticsearch::Transport::Transport::Errors::GatewayTimeout).ordered

            is_expected.to receive(:fast_reindex)
              .with(client, test_model_previous_version, client, test_model.versioned_index_name, true).ordered

            info = subject.smart_reindex_indices

            expect(client.indices.exists index: test_model_previous_version).to be_falsey
            expect(client.indices.exists index: test_model.versioned_index_name).to be_truthy
            expect(client.indices.exists_alias? name: test_model.index_name)
            existing_alias_info = client.indices.get_alias name: test_model.index_name
            expect(existing_alias_info[test_model.versioned_index_name]["aliases"]).to have_key test_model.index_name

            expect(subject.has_errors).to be_falsey
            expect(info[:reindexed]).to have_key "#{test_model}"
            expect(info[:reindexed]["#{test_model}"][:from]).to eq test_model_previous_version
            expect(info[:reindexed]["#{test_model}"][:to]).to eq test_model.versioned_index_name
          }
        end
      end

      context 'index_name aliased to previous versioned_index_name with different migration_version' do
        let(:test_model) { DataFile }
        let(:test_model_previous_version) { "#{test_model.index_name}_#{test_model.mapping_version}_#{SecureRandom.uuid}" }

        around :each do |example|
          client = Elasticsearch::Model.client
          client.indices.delete index: '_all'
          FolderFilesResponse.indexed_models.each do |indexed_model|
            previous_version = ("#{indexed_model}" == "#{test_model}") ? test_model_previous_version : indexed_model.versioned_index_name
            client.indices.create(
              index: previous_version,
              body: {
                settings: indexed_model.settings.to_hash,
                mappings: indexed_model.mappings.to_hash
              }
            )
            client.indices.put_alias index: previous_version, name: indexed_model.index_name
          end
          client.indices.flush

          data_file = FactoryBot.create(:data_file)
          data_file.__elasticsearch__.index_document
          folder = FactoryBot.create(:folder)
          folder.__elasticsearch__.index_document

          FolderFilesResponse.indexed_models.each do |indexed_model|
            indexed_model.__elasticsearch__.refresh_index!
          end

          example.run

          client.indices.delete index: '_all'
        end

        it {
          client = Elasticsearch::Model.client
          expect(test_model_previous_version).not_to match test_model.migration_version
          expect(client.indices.exists index: test_model_previous_version).to be_truthy
          expect(client.indices.exists index: test_model.versioned_index_name).to be_falsey
          expect(client.indices.exists_alias? name: test_model.index_name)
          existing_alias_info = client.indices.get_alias name: test_model.index_name
          expect(existing_alias_info[test_model_previous_version]["aliases"]).to have_key test_model.index_name

          info = subject.smart_reindex_indices

          expect(client.indices.exists index: test_model_previous_version).to be_truthy
          expect(client.indices.exists index: test_model.versioned_index_name).to be_falsey
          expect(client.indices.exists_alias? name: test_model.index_name)
          existing_alias_info = client.indices.get_alias name: test_model.index_name
          expect(existing_alias_info[test_model_previous_version]["aliases"]).to have_key test_model.index_name

          expect(info[:migration_version_mismatch]).to have_key "#{test_model}"
          expect(info[:migration_version_mismatch]["#{test_model}"][:from]).to eq test_model_previous_version
          expect(info[:migration_version_mismatch]["#{test_model}"][:to]).to eq test_model.migration_version
        }
      end
    end
  end

  describe '#start_scroll' do
    it { is_expected.not_to respond_to(:start_scroll).with(0).arguments }
    it { is_expected.not_to respond_to(:start_scroll).with(1).arguments }
    it { is_expected.to respond_to(:start_scroll).with(2).arguments }
    it { is_expected.to respond_to(:start_scroll).with(2).arguments.and_keywords(:scroll, :body) }

    context 'interface' do
      let(:client) { instance_double(Elasticsearch::Transport::Client) }
      let(:source_index) { 'source_index' }
      let(:expected_scroll_id) { SecureRandom.hex }
      let(:search_response) {
        {
          '_scroll_id' => expected_scroll_id,
          'hits' => {
            'hits' => [
              {'id' => SecureRandom.uuid }
            ]
          }
        }
      }
      let(:expected_scroll) { '1m' }
      let(:expected_body) { {size: 10000, sort: ['_doc']} }

      context 'without body and scroll' do
        it {
          expect(client).to receive(:search)
            .with(index: source_index, scroll: expected_scroll, body: expected_body)
            .and_return(search_response)
          resp = subject.start_scroll(client, source_index)
          expect(resp).to eq(search_response)
          expect(subject.current_scroll_id).to eq(expected_scroll_id)
        }
      end

      context 'with scroll' do
        let(:expected_scroll) { '5m' }
        it {
          expect(client).to receive(:search)
            .with(index: source_index, scroll: expected_scroll, body: expected_body)
            .and_return(search_response)
          resp = subject.start_scroll(client, source_index, scroll: expected_scroll)
          expect(resp).to eq(search_response)
          expect(subject.current_scroll_id).to eq(expected_scroll_id)
        }
      end

      context 'with body' do
        let(:expected_body) { {match_all: {}} }
        it {
          expect(client).to receive(:search)
            .with(index: source_index, scroll: expected_scroll, body: expected_body)
            .and_return(search_response)
          resp = subject.start_scroll(client, source_index, body: expected_body)
          expect(resp).to eq(search_response)
          expect(subject.current_scroll_id).to eq(expected_scroll_id)
        }
      end

      context 'with body and scroll' do
        let(:expected_scroll) { '5m' }
        let(:expected_body) { {match_all: {}} }
        it {
          expect(client).to receive(:search)
            .with(index: source_index, scroll: expected_scroll, body: expected_body)
            .and_return(search_response)
          resp = subject.start_scroll(client, source_index, scroll: expected_scroll, body: expected_body)
          expect(resp).to eq(search_response)
          expect(subject.current_scroll_id).to eq(expected_scroll_id)
        }
      end
    end

    context 'live' do
      let (:client) { Elasticsearch::Model.client }
      let(:source_index) { DataFile.index_name }
      let(:indexed_data_file) { FactoryBot.create(:data_file) }
      let(:indexed_folder) { FactoryBot.create(:folder) }
      include_context 'elasticsearch prep', [], [:indexed_data_file, :indexed_folder]

      it {
        resp = subject.start_scroll(client, source_index)
        expect(resp).to have_key '_scroll_id'
        expect(subject.current_scroll_id).to eq(resp['_scroll_id'])
        expect(resp).to have_key 'hits'
        expect(resp['hits']).to have_key 'hits'
      }
    end
  end

  describe '#next_scroll' do
    it { is_expected.not_to respond_to(:next_scroll).with(0).arguments }
    it { is_expected.to respond_to(:next_scroll).with(1).arguments }
    it { is_expected.to respond_to(:next_scroll).with(1).arguments.and_keywords(:scroll) }

    context 'interface' do
      let(:client) { instance_double(Elasticsearch::Transport::Client) }
      let(:initial_scroll_id) { SecureRandom.hex }
      let(:intial_search_response) {
        {
          '_scroll_id' => initial_scroll_id,
          'hits' => {
            'hits' => [
              {'id' => SecureRandom.uuid }
            ]
          }
        }
      }
      let(:expected_scroll_id) { SecureRandom.hex }
      let(:search_response) {
        {
          '_scroll_id' => expected_scroll_id,
          'hits' => {
            'hits' => [
              {'id' => SecureRandom.uuid }
            ]
          }
        }
      }
      let(:expected_scroll_id) { SecureRandom.hex }
      let(:expected_scroll) { '5m' }

      before do
        expect(client).to receive(:search)
          .with(index: 'source_index', scroll: '1m', body: {size: 10000, sort: ['_doc']})
          .and_return(intial_search_response)
        subject.start_scroll(client, 'source_index')
      end
      context 'without scroll' do
        it {
          expect(subject.current_scroll_id).to eq(initial_scroll_id)
          expect(client).to receive(:scroll)
            .with(scroll_id: initial_scroll_id, scroll: expected_scroll)
            .and_return(search_response)
          resp = subject.next_scroll(client)
          expect(resp).to eq(search_response)
          expect(subject.current_scroll_id).to eq(expected_scroll_id)
        }
      end

      context 'with scroll' do
        let(:expected_scroll) { '10s' }
        it {
          expect(subject.current_scroll_id).to eq(initial_scroll_id)
          expect(client).to receive(:scroll)
            .with(scroll_id: initial_scroll_id, scroll: expected_scroll)
            .and_return(search_response)
          resp = subject.next_scroll(client, scroll: expected_scroll)
          expect(resp).to eq(search_response)
          expect(subject.current_scroll_id).to eq(expected_scroll_id)
        }
      end
    end

    context 'live' do
      let (:client) { Elasticsearch::Model.client }
      let(:start_scroll) { subject.start_scroll(client, DataFile.index_name ) }
      let(:indexed_data_file) { FactoryBot.create(:data_file) }
      let(:indexed_folder) { FactoryBot.create(:folder) }
      include_context 'elasticsearch prep', [], [:indexed_data_file, :indexed_folder]

      it {
        expect(start_scroll).not_to be_nil
        expect(subject.current_scroll_id).to eq(start_scroll['_scroll_id'])
        resp = subject.next_scroll(client)
        expect(resp).to have_key '_scroll_id'
        expect(subject.current_scroll_id).to eq(resp['_scroll_id'])
        expect(resp).to have_key 'hits'
        expect(resp['hits']).to have_key 'hits'
      }
    end
  end

  describe '#send_batch' do
    it { is_expected.not_to respond_to(:send_batch).with(0).arguments }
    it { is_expected.not_to respond_to(:send_batch).with(1).arguments }
    it { is_expected.to respond_to(:send_batch).with(2).arguments }

    context 'interface' do
      let(:client) { instance_double(Elasticsearch::Transport::Client) }
      let(:batch) { 'batch' }
      it {
        expect(client).to receive(:bulk).with(body: batch)
        subject.send_batch(client, batch)
      }
    end

    context 'live' do
      let(:client) { Elasticsearch::Model.client }
      let(:indexed_data_file) { FactoryBot.create(:data_file) }
      let(:indexed_folder) { FactoryBot.create(:folder) }
      let(:indexed_model) { DataFile }
      let(:source_index) { indexed_model.index_name }
      let(:target_index) { 'new_index' }
      let(:request) { subject.start_scroll(client, source_index) }
      let(:batch) {
        subject.batch_from_search(
          target_index,
          request
        )
      }
      include_context 'elasticsearch prep', [], [:indexed_data_file, :indexed_folder]

      it {
        client.indices.create(
          index: target_index,
          body: {
            settings: indexed_model.settings.to_hash,
            mappings: indexed_model.mappings.to_hash
          }
        )
        client.indices.flush
        resp = subject.send_batch(client, batch)
        expect(resp).to have_key "errors"
        expect(resp["errors"]).to be_falsey

        client.indices.flush
        check_index_resp = client.search index: target_index, body: {query: {match_all: {}}}
        expect(check_index_resp).to have_key 'hits'
        expect(check_index_resp['hits']).to have_key 'hits'
        expect(check_index_resp['hits']['total']).to eq 1
        hit = check_index_resp['hits']['hits'].first
        expect(hit['_id']).to eq indexed_data_file.id
      }
    end
  end

  describe '#batch_from_search' do
    let(:index) { 'index' }
    let(:expected_hit) {{
      '_type' => 'hit_type',
      '_id' => 'hit_id',
      '_source' => 'hit_source'
    }}
    let(:request) {{
        'hits' => {
          'hits' => [
            expected_hit
          ]
        }
    }}
    let(:expected_batch) {[
      {
        index: {
          _index: index,
          _type: expected_hit['_type'],
          _id: expected_hit['_id'],
          data: expected_hit['_source']
        }
      }
    ]}

    it { is_expected.not_to respond_to(:batch_from_search).with(0).arguments }
    it { is_expected.not_to respond_to(:batch_from_search).with(1).arguments }
    it { is_expected.to respond_to(:batch_from_search).with(2).arguments }
    it {
      expect(subject.batch_from_search(index, request)).to eq(expected_batch)
    }
  end

  describe '#fast_reindex' do
    let(:source_index) { 'source_index' }
    let(:source_client) { instance_double(Elasticsearch::Transport::Client) }

    let(:target_index) { 'target_index' }
    let(:target_client) { instance_double(Elasticsearch::Transport::Client)  }

    it { is_expected.not_to respond_to(:fast_reindex).with(0).arguments }
    it { is_expected.not_to respond_to(:fast_reindex).with(1).arguments }
    it { is_expected.not_to respond_to(:fast_reindex).with(2).arguments }
    it { is_expected.not_to respond_to(:fast_reindex).with(2).arguments }
    it { is_expected.to respond_to(:fast_reindex).with(4).arguments }
    it { is_expected.to respond_to(:fast_reindex).with(5).arguments }

    context 'without errors' do
      let(:first_scroll_id) { SecureRandom.hex }
      let(:second_scroll_id) { SecureRandom.hex }
      let(:expected_first_response) {{
        '_scroll_id' => first_scroll_id,
        'hits' => {
          'hits' => [
            {'id' => SecureRandom.uuid }
          ]
        }
      }}
      let(:expected_first_batch) {{}}
      let(:first_batch_response) {{}}
      let(:expected_second_response) {{
        '_scroll_id' => second_scroll_id,
        'hits' => {
          'hits' => [
            {'id' => SecureRandom.uuid }
          ]
        }
      }}
      let(:expected_second_batch) {{}}
      let(:second_batch_response) {{}}
      let(:empty_response) {{
        'hits' => {
          'hits' => []
        }
      }}

      it {
        is_expected.to receive(:start_scroll)
          .with(source_client, source_index)
          .and_return(expected_first_response)

        is_expected.to receive(:batch_from_search)
          .with(target_index, expected_first_response)
          .and_return(expected_first_batch)

        is_expected.to receive(:send_batch)
          .with(target_client, expected_first_batch)
          .and_return(first_batch_response)

        is_expected.to receive(:next_scroll)
          .with(source_client)
          .and_return(expected_second_response)

        is_expected.to receive(:batch_from_search)
          .with(target_index, expected_second_response)
          .and_return(expected_second_batch)

        is_expected.to receive(:send_batch)
          .with(target_client, expected_second_batch)
          .and_return(second_batch_response)

        is_expected.to receive(:next_scroll)
          .with(source_client)
          .and_return(empty_response)

        subject.fast_reindex(source_client, source_index, target_client, target_index)
        expect(subject.has_errors).to be_falsey
      }
    end

    context 'with errors' do
      let(:first_scroll_id) { SecureRandom.hex }
      let(:second_scroll_id) { SecureRandom.hex }
      let(:failed_id) { SecureRandom.uuid }
      let(:expected_first_response) {{
        '_scroll_id' => first_scroll_id,
        'hits' => {
          'hits' => [
            {'id' => SecureRandom.uuid }
          ]
        }
      }}
      let(:expected_first_batch) {{}}
      let(:first_batch_response) {{
        "errors" => true,
        "items" => [
          {"index" => { "status" => 403, "_id" => failed_id }}
        ]
      }}
      let(:expected_second_response) {{
        '_scroll_id' => second_scroll_id,
        'hits' => {
          'hits' => [
            {'id' => SecureRandom.uuid}
          ]
        }
      }}
      let(:expected_second_batch) {{}}
      let(:second_batch_response) {{}}
      let(:empty_response) {{
        'hits' => {
          'hits' => []
        }
      }}
      let(:call_fast_reindex) { subject.fast_reindex(source_client, source_index, target_client, target_index) }

      before(:example) do
        is_expected.to receive(:start_scroll)
          .with(source_client, source_index)
          .and_return(expected_first_response)

        is_expected.to receive(:batch_from_search)
          .with(target_index, expected_first_response)
          .and_return(expected_first_batch)

        is_expected.to receive(:send_batch)
          .with(target_client, expected_first_batch)
          .and_return(first_batch_response)

        is_expected.to receive(:next_scroll)
          .with(source_client)
          .and_return(expected_second_response)

        is_expected.to receive(:batch_from_search)
          .with(target_index, expected_second_response)
          .and_return(expected_second_batch)

        is_expected.to receive(:send_batch)
          .with(target_client, expected_second_batch)
          .and_return(second_batch_response)

        is_expected.to receive(:next_scroll)
          .with(source_client)
          .and_return(empty_response)
      end

      it { expect { call_fast_reindex }.to change { subject.has_errors }.from(false).to(true) }

      context 'in verbose mode' do
        subject { verbose_subject }
        it { expect { call_fast_reindex }.to output(/^errors:\n."*#{failed_id}".*$/im).to_stderr }
      end
    end

    context 'retry' do
      let(:first_scroll_id) { SecureRandom.hex }
      let(:second_scroll_id) { SecureRandom.hex }
      let(:expected_first_response) {{
        '_scroll_id' => second_scroll_id,
        'hits' => {
          'hits' => [
            {'id' => SecureRandom.uuid }
          ]
        }
      }}
      let(:expected_first_batch) {{}}
      let(:first_batch_response) {{}}
      let(:empty_response) {{
        'hits' => {
          'hits' => []
        }
      }}

      it {
        is_expected.to receive(:next_scroll)
          .with(source_client)
          .and_return(expected_first_response)

        is_expected.to receive(:batch_from_search)
          .with(target_index, expected_first_response)
          .and_return(expected_first_batch)

        is_expected.to receive(:send_batch)
          .with(target_client, expected_first_batch)
          .and_return(first_batch_response)

        is_expected.to receive(:next_scroll)
          .with(source_client)
          .and_return(empty_response)

        subject.fast_reindex(source_client, source_index, target_client, target_index, true)
        expect(subject.has_errors).to be_falsey
      }
    end
  end
end
