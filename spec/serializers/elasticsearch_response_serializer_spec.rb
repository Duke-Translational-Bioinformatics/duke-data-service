require 'rails_helper'

RSpec.describe ElasticsearchResponseSerializer, type: :serializer do
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
  let(:indices) { ElasticsearchResponse.indexed_models }

  let(:indexed_data_file) {
    FactoryGirl.create(:data_file, name: "foo")
  }
  let(:indexed_folder) {
    FactoryGirl.create(:folder, name: "foo")
  }

  let(:resource) {
    ElasticsearchResponse.new(
      query: elastic_query,
      indices: indices,
      policy_scope: policy_scope
    )
  }

  around :each do |example|
    current_indices = DataFile.__elasticsearch__.client.cat.indices
    ElasticsearchResponse.indexed_models.each do |indexed_model|
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

    example.run

    ElasticsearchResponse.indexed_models.each do |indexed_model|
      indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
    end
  end

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('results')
      [indexed_folder, indexed_data_file].each do |eresult|
        expect(subject['results']).to include JSON.parse(ActiveModel::Serializer.serializer_for(eresult).new(eresult).to_json)
      end
    end
  end
end
