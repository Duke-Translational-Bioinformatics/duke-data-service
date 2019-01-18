require 'rails_helper'

RSpec.describe DeprecatedElasticsearchResponse do
  include_context 'mock all Uploads StorageProvider'

  it { expect(described_class).to respond_to 'indexed_models' }

  let(:policy_scope) { Proc.new {|scope| scope } }
  let(:elastic_query) {
    {
      query: {
        query_string: {
          query: "foo"
        }
      }
    }
  }

  let(:indexed_data_file) {
    FactoryBot.create(:data_file, name: "foo")
  }
  let(:indexed_folder) {
    FactoryBot.create(:folder, name: "foo")
  }

  it { expect(described_class).to include(ActiveModel::Serialization) }

  context 'elasticsearch' do
    context 'initialization' do
      let(:indices) { DeprecatedElasticsearchResponse.indexed_models }

      context 'no arguments' do
        subject {
          described_class.new()
        }
        it {
          expect{
            subject
          }.to raise_error(ArgumentError)
        }
      end

      context 'missing elastic_query and policy_scope' do
        subject {
          described_class.new(
            indices: indices
          )
        }
        it {
          expect{
            subject
          }.to raise_error(ArgumentError)
        }
      end

      context 'unsupported index' do
        subject {
          described_class.new(
            query: elastic_query,
            indices: [Project],
            policy_scope: policy_scope
          )
        }
        it {
          expect{
            subject
          }.to raise_error(NameError)
        }
      end

      context 'missing policy_scope' do
        subject {
          described_class.new(
            query: elastic_query,
            indices: indices
          )
        }
        it {
          expect{
            subject
          }.to raise_error(ArgumentError)
        }
      end

      context 'all arguments correct' do
        subject {
          described_class.new(
            query: elastic_query,
            indices: indices,
            policy_scope: policy_scope
          )
        }
        it {
          current_indices = DataFile.__elasticsearch__.client.cat.indices
          DeprecatedElasticsearchResponse.indexed_models.each do |indexed_model|
            if current_indices.include? indexed_model.index_name
              indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
            end
            indexed_model.__elasticsearch__.client.indices.create(
              index: indexed_model.index_name,
              body: {
                settings: indexed_model.settings.to_hash,
                mappings: indexed_model.mappings.to_hash
              }
            )
          end

          expect(indexed_folder).to be_persisted
          indexed_folder.__elasticsearch__.index_document
          expect(indexed_data_file).to be_persisted
          indexed_data_file.__elasticsearch__.index_document

          Folder.__elasticsearch__.refresh_index!
          DataFile.__elasticsearch__.refresh_index!

          expect{
            subject
          }.not_to raise_error

          DeprecatedElasticsearchResponse.indexed_models.each do |indexed_model|
            indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
          end
        }
      end
    end

    context 'instantiations' do
      include_context 'elasticsearch prep', [], [:indexed_folder, :indexed_data_file]

      context 'single index' do
        let(:indices) { [DataFile] }
        subject {
          described_class.new(
            query: elastic_query,
            indices: indices,
            policy_scope: policy_scope
          )
        }

        it {
          expect(subject.results).to include indexed_data_file
          expect(subject.results).not_to include indexed_folder
        }
      end

      context 'multi index' do
        let(:indices) { DeprecatedElasticsearchResponse.indexed_models }
        subject {
          described_class.new(
            query: elastic_query,
            indices: indices,
            policy_scope: policy_scope
          )
        }

        it {
          expect(subject.results).to include indexed_folder
          expect(subject.results).to include indexed_data_file
        }
      end

      context 'restrictive policy_scope' do
        let(:indices) { [Folder] }
        let(:policy_scope) { Proc.new { |scope| scope.none } }
        let(:indices) { DeprecatedElasticsearchResponse.indexed_models }
        subject {
          described_class.new(
            query: elastic_query,
            indices: indices,
            policy_scope: policy_scope
          )
        }
        it {
          expect(subject.results).to be_empty
        }
      end
    end
  end
end
