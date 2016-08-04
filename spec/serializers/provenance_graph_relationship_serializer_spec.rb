require 'rails_helper'

RSpec.describe ProvenanceGraphRelationshipSerializer, type: :serializer do
  # (activity)-(used)->(focus)
  let!(:focus) {
    FactoryGirl.create(:file_version, label: "FOCUS")
  }

  let!(:activity) { FactoryGirl.create(:activity, name: "ACTIVITY") }
  let!(:activity_used_focus) {
    FactoryGirl.create(:used_prov_relation,
      relatable_from: activity,
      relatable_to: focus
    )
  }
  let!(:relationship) { activity_used_focus.graph_relation }

  context 'with properties' do
    let(:resource) {
      res = ProvenanceGraphRelationship.new(relationship)
      res.properties = activity_used_focus
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
        is_expected.to have_key('type')
        is_expected.to have_key('start_node')
        is_expected.to have_key('end_node')
        is_expected.to have_key('properties')
        expect(subject["id"]).to eq(resource.id)
        expect(subject["type"]).to eq(resource.type)
        expect(subject["start_node"]).to eq(resource.start_node)
        expect(subject["end_node"]).to eq(resource.end_node)
        expect(subject["properties"]).to eq(expected_properties)
      end
    end
  end

  context 'without properties' do
    let(:resource) {
      ProvenanceGraphRelationship.new(relationship)
    }

    it_behaves_like 'a json serializer' do
      it 'should have expected keys and values' do
        is_expected.to have_key('id')
        is_expected.to have_key('type')
        is_expected.to have_key('start_node')
        is_expected.to have_key('end_node')
        is_expected.to have_key('properties')
        expect(subject["id"]).to eq(resource.id)
        expect(subject["type"]).to eq(resource.type)
        expect(subject["start_node"]).to eq(resource.start_node)
        expect(subject["end_node"]).to eq(resource.end_node)
        expect(subject["properties"]).to be_nil
      end
    end
  end
end
