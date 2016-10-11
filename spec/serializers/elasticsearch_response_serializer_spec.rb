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

  include_context 'elasticsearch prep', [], [:indexed_folder, :indexed_data_file]

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('results')
      [indexed_folder, indexed_data_file].each do |eresult|
        expect(subject['results']).to include JSON.parse(ActiveModel::Serializer.serializer_for(eresult).new(eresult).to_json)
      end
    end
  end
end
