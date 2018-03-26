require 'rails_helper'

describe "elasticsearch" do
  let(:elasticsearch_handler) { instance_double(ElasticsearchHandler) }

  describe "elasticsearch:index:create" do
    include_context "rake"
    let(:task_name) { "elasticsearch:index:create" }
    it { expect(subject.prerequisites).to  include("environment") }

    context 'ENV[TARGET_URL] not set' do
      before { expect(ElasticsearchHandler).to receive(:new).with(verbose: true).and_return(elasticsearch_handler) }
      it {
        expect(elasticsearch_handler).to receive(:create_indices)
        invoke_task
      }
    end

    context 'ENV[TARGET_URL] set' do
      let(:expected_url) { Faker::Internet.url }
      let(:expected_client) { instance_double(Elasticsearch::Transport::Client) }
      include_context 'with env_override'
      let(:env_override) { {
        'TARGET_URL' => expected_url
      } }

      before {
        expect(Elasticsearch::Client).to receive(:new).with(url: expected_url).and_return(expected_client)
        expect(ElasticsearchHandler).to receive(:new).with(verbose: true).and_return(elasticsearch_handler)
      }
      it {
        expect(elasticsearch_handler).to receive(:create_indices).with(expected_client)
        invoke_task
      }
    end
  end

  describe "elasticsearch:index:index_documents" do
    include_context "rake"
    let(:task_name) { "elasticsearch:index:index_documents" }
    it { expect(subject.prerequisites).to  include("environment") }

    context 'called' do
      before { expect(ElasticsearchHandler).to receive(:new).with(verbose: true).and_return(elasticsearch_handler) }
      it {
        expect(elasticsearch_handler).to receive(:index_documents)
        invoke_task
      }
    end
  end

  describe "elasticsearch:index:drop" do
    include_context "rake"
    let(:task_name) { "elasticsearch:index:drop" }
    it { expect(subject.prerequisites).to  include("environment") }

    context 'ENV[TARGET_URL] not set' do
      before { expect(ElasticsearchHandler).to receive(:new).with(verbose: true).and_return(elasticsearch_handler) }
      it {
        expect(elasticsearch_handler).to receive(:drop_indices)
        invoke_task
      }
    end

    context 'ENV[TARGET_URL] set' do
      let(:expected_url) { Faker::Internet.url }
      let(:expected_client) { instance_double(Elasticsearch::Transport::Client) }
      include_context 'with env_override'
      let(:env_override) { {
        'TARGET_URL' => expected_url
      } }

      before {
        expect(Elasticsearch::Client).to receive(:new).with(url: expected_url).and_return(expected_client)
        expect(ElasticsearchHandler).to receive(:new).with(verbose: true).and_return(elasticsearch_handler)
      }
      it {
        expect(elasticsearch_handler).to receive(:drop_indices).with(expected_client)
        invoke_task
      }
    end
  end

  describe "elasticsearch:index:rebuild" do
    include_context "rake"
    let(:task_name) { "elasticsearch:index:rebuild" }
    it { expect(subject.prerequisites).to  include("environment") }

    context 'ENV[RECREATE_SEARCH_MAPPINGS] not true' do
      it {
        invoke_task expected_stderr: /ENV\[RECREATE_SEARCH_MAPPINGS\] false/
      }
    end

    context 'ENV[RECREATE_SEARCH_MAPPINGS] true' do
      context 'called' do
        include_context 'with env_override'
        let(:env_override) { {
          'RECREATE_SEARCH_MAPPINGS' => "true"
        } }

        before { expect(ElasticsearchHandler).to receive(:new).with(verbose: true).and_return(elasticsearch_handler) }
        it {
          expect(elasticsearch_handler).to receive(:drop_indices)
          expect(elasticsearch_handler).to receive(:create_indices)
          expect(elasticsearch_handler).to receive(:index_documents)
          invoke_task expected_stdout: /mappings rebuilt/
        }
      end
    end
  end

  describe 'elasticsearch:index:smart_reindex' do
    include_context "rake"
    let(:task_name) { "elasticsearch:index:smart_reindex" }
    it { expect(subject.prerequisites).to  include("environment") }

    context 'versioned_index_name exists' do
      let(:skipped_index) { DataFile.versioned_index_name }
      let(:expected_info) {
        {
          skipped: [skipped_index],
          reindexed: {},
          migration_version_mismatch: {},
          missing_aliases: [],
          has_errors: []
        }
      }
      before { expect(ElasticsearchHandler).to receive(:new).with(verbose: true).and_return(elasticsearch_handler) }
      it {
        expect(elasticsearch_handler).to receive(:smart_reindex_indices).and_return(expected_info)
        invoke_task expected_stderr: /#{skipped_index} index exists, nothing more to do/
      }
    end

    context 'versioned_index_name does not exist' do
      context 'index_name alias does not exist' do
        let(:missing_alias) { DataFile.index_name }
        let(:expected_info) {
          {
            skipped: [],
            reindexed: {},
            migration_version_mismatch: {},
            missing_aliases: [missing_alias],
            has_errors: []
          }
        }
        before { expect(ElasticsearchHandler).to receive(:new).with(verbose: true).and_return(elasticsearch_handler) }
        it {
          expect(elasticsearch_handler).to receive(:smart_reindex_indices).and_return(expected_info)
          invoke_task expected_stderr: /#{missing_alias} alias does not exist!/
        }
      end

      context 'index_name aliased to previous versioned_index_name with same migration_version' do
        let(:indexed_model) { DataFile }
        let(:previous_version) { "#{indexed_model.index_name}_#{SecureRandom.uuid}_#{indexed_model.migration_version}" }
        let(:expected_info) {
          {
            skipped: [],
            reindexed: {
              "#{indexed_model}" => {from: previous_version, to: indexed_model.versioned_index_name}
            },
            migration_version_mismatch: {},
            missing_aliases: [],
            has_errors: []
          }
        }
        before { expect(ElasticsearchHandler).to receive(:new).with(verbose: true).and_return(elasticsearch_handler) }
        it {
          expect(elasticsearch_handler).to receive(:smart_reindex_indices).and_return(expected_info)
          invoke_task expected_stderr: /index for #{indexed_model} reindexed from #{previous_version} to #{indexed_model.versioned_index_name}/
        }
      end

      context 'index_name aliased to previous versioned_index_name with different migration_version' do
        let(:indexed_model) { DataFile }
        let(:previous_version) { "#{indexed_model.index_name}_#{indexed_model.mapping_version}_#{SecureRandom.uuid}" }
        let(:expected_info) {
          {
            skipped: [],
            reindexed: {},
            migration_version_mismatch: {
              "#{indexed_model}" => {from: previous_version, to: indexed_model.migration_version}
            },
            missing_aliases: [],
            has_errors: []
          }
        }
        before { expect(ElasticsearchHandler).to receive(:new).with(verbose: true).and_return(elasticsearch_handler) }
        it {
          expect(elasticsearch_handler).to receive(:smart_reindex_indices).and_return(expected_info)
          invoke_task expected_stderr: /#{indexed_model} #{previous_version} migration_version does not match #{indexed_model.migration_version}/
        }
      end
    end
  end

  describe 'elasticsearch:index:fast_reindex' do
    include_context "rake"
    let(:task_name) { "elasticsearch:index:fast_reindex" }
    it { expect(subject.prerequisites).to  include("environment") }

    context 'ENV[SOURCE_INDEX] not set' do
      it {
        invoke_task expected_stderr: /ENV\[SOURCE_INDEX\] and ENV\[TARGET_INDEX\] are required/
      }
    end

    context 'ENV[TARGET_INDEX] not set' do
      it {
        invoke_task expected_stderr: /ENV\[SOURCE_INDEX\] and ENV\[TARGET_INDEX\] are required/
      }
    end

    context 'ENV[TARGET_URL] is not set' do
      let(:expected_source_client) { Elasticsearch::Model.client }
      let(:expected_target_client) { Elasticsearch::Model.client }
      let(:expected_source_index) { 'source_index' }
      let(:expected_target_index) { 'target_index' }
      include_context 'with env_override'
      let(:env_override) { {
        'SOURCE_INDEX' => expected_source_index,
        'TARGET_INDEX' => expected_target_index
      } }

      before { expect(ElasticsearchHandler).to receive(:new).with(verbose: true).and_return(elasticsearch_handler) }
      context 'without errors' do
        it {
          expect(elasticsearch_handler).to receive(:fast_reindex)
            .with(expected_source_client,
                  expected_source_index,
                  expected_target_client,
                  expected_target_index,
                  false)
          expect(elasticsearch_handler).to receive(:has_errors)
            .and_return(false)
          invoke_task expected_stderr: /reindex complete/
        }
      end

      context 'with errors' do
        it {
          expect(elasticsearch_handler).to receive(:fast_reindex)
            .with(expected_source_client,
                  expected_source_index,
                  expected_target_client,
                  expected_target_index,
                  false)
            expect(elasticsearch_handler).to receive(:has_errors)
              .and_return(true)
          invoke_task expected_stderr: /errors occurred/
        }
      end

      context 'retry' do
        it {
          expect(elasticsearch_handler).to receive(:fast_reindex)
            .with(expected_source_client,
                  expected_source_index,
                  expected_target_client,
                  expected_target_index,
                  false)
            .and_raise(Elasticsearch::Transport::Transport::Errors::GatewayTimeout)
            .ordered
            expect(elasticsearch_handler).to receive(:fast_reindex)
              .with(expected_source_client,
                    expected_source_index,
                    expected_target_client,
                    expected_target_index,
                    true)
              .ordered
          expect(elasticsearch_handler).to receive(:has_errors)
            .and_return(false)
          invoke_task expected_stderr: /reindex complete/
        }
      end
    end

    context 'ENV[TARGET_URL] is set' do
      let(:target_url) { Faker::Internet.url }
      let(:expected_source_client) { Elasticsearch::Model.client }
      let(:expected_target_client) { instance_double(Elasticsearch::Transport::Client)  }
      let(:expected_source_index) { 'source_index' }
      let(:expected_target_index) { 'target_index' }
      include_context 'with env_override'
      let(:env_override) { {
        'SOURCE_INDEX' => expected_source_index,
        'TARGET_INDEX' => expected_target_index,
        'TARGET_URL' => target_url
      } }

      before {
        expect(Elasticsearch::Client).to receive(:new).with(url: target_url).and_return(expected_target_client)
        expect(ElasticsearchHandler).to receive(:new).with(verbose: true).and_return(elasticsearch_handler)
      }
      context 'without errors' do
        it {
          expect(elasticsearch_handler).to receive(:fast_reindex)
            .with(expected_source_client,
                  expected_source_index,
                  expected_target_client,
                  expected_target_index,
                false)
          expect(elasticsearch_handler).to receive(:has_errors)
            .and_return(false)
          invoke_task expected_stderr: /reindex complete/
        }
      end

      context 'with errors' do
        it {
          expect(elasticsearch_handler).to receive(:fast_reindex)
            .with(expected_source_client,
                  expected_source_index,
                  expected_target_client,
                  expected_target_index,
                false)
            expect(elasticsearch_handler).to receive(:has_errors)
              .and_return(true)
          invoke_task expected_stderr: /errors occurred/
        }
      end
    end
  end
end
