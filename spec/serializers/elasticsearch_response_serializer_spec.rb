require 'rails_helper'

RSpec.describe ElasticsearchResponseSerializer, type: :serializer do
  let(:indexed_data_file) {
    FactoryGirl.create(:data_file, name: "foo")
  }
  let(:indexed_folder) {
    FactoryGirl.create(:folder, name: "foo")
  }
  let(:filters) {[
    {'project.id' => [
      indexed_folder.project.id,
      indexed_data_file.project.id
    ]}
  ]}

  include_context 'elasticsearch prep', [], [:indexed_folder, :indexed_data_file]

  context 'without aggs' do
    let(:resource) {  ElasticsearchResponse.new }
    before do
      resource.filter(filters).search
    end

    it_behaves_like 'a json serializer' do
      it 'should have expected keys and values' do
        is_expected.to have_key('results')
        [indexed_folder, indexed_data_file].each do |eresult|
          expect(subject['results'].collect &:to_json).to include eresult.as_indexed_json.to_json
        end
        is_expected.not_to have_key('aggs')
      end
    end
  end

  context 'with aggs' do
    let(:resource) {  ElasticsearchResponse.new }
    let(:agg_field) { 'project.name' }
    let(:agg_name) { 'project_name' }
    let(:aggs) {
      [{field: agg_field, name: agg_name}]
    }
    let(:project_names) {[
      indexed_folder.project.name,
      indexed_data_file.project.name
    ]}

    before do
      resource.filter(filters).aggregate(aggs).search
    end

    it_behaves_like 'a json serializer' do
      it 'should have expected keys and values' do
        is_expected.to have_key('results')
        [indexed_folder, indexed_data_file].each do |eresult|
          expect(subject['results'].collect &:to_json).to include eresult.as_indexed_json.to_json
        end
        is_expected.to have_key('aggs')
        expect(subject['aggs']).to have_key(agg_name)
        expect(subject['aggs'][agg_name]).to have_key('buckets')
        expect(subject['aggs'][agg_name]['buckets']).to be_an Array
        expect(subject['aggs'][agg_name]['buckets'].length).to eq(2)
        subject['aggs'][agg_name]['buckets'].each do |bucket|
          expect(bucket).to have_key('key')
          expect(project_names).to include(bucket['key'])
        end
      end
    end
  end
end
