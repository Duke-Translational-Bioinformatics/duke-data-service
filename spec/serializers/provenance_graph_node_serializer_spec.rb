require 'rails_helper'

RSpec.describe ProvenanceGraphNodeSerializer, type: :serializer do
  let!(:focus) {
    FactoryGirl.create(:file_version, label: "FOCUS")
  }
  let(:node) { focus.graph_node }

  let(:resource) {
    res = ProvenanceGraphNode.new(node)
    res.properties = focus
    res
  }

  it_behaves_like 'a json serializer' do
    let(:expected_properties_object) { resource.properties }
    let(:expected_properties_json) {
      ActiveModel::Serializer.serializer_for(expected_properties_object).new(
        expected_properties_object
      ).to_json
    }
    let(:expected_properties) { JSON.parse(expected_properties_json) }
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('labels')
      is_expected.to have_key('properties')
      expect(subject["id"]).to eq(resource.id)
      expect(subject["labels"]).to eq(resource.labels)
      expect(subject["properties"]).to eq(expected_properties)
    end
  end
end
