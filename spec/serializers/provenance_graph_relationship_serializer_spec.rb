require 'rails_helper'

RSpec.describe ProvenanceGraphRelationshipSerializer, type: :serializer do
  include_context 'mock all Uploads StorageProvider'
  include_context 'performs enqueued jobs', only: GraphPersistenceJob
  # (activity)-(used)->(focus)
  let!(:focus) {
    FactoryBot.create(:file_version, label: "FOCUS")
  }

  let!(:activity) { FactoryBot.create(:activity, name: "ACTIVITY") }
  let!(:activity_used_focus) {
    FactoryBot.create(:used_prov_relation,
      relatable_from: activity,
      relatable_to: focus
    )
  }
  let!(:relationship) { activity_used_focus.graph_relation }

  context 'not restricted' do
    let(:resource) { ProvenanceGraphRelationship.new(relationship) }
    let(:expected_attributes) {{
      'id' => resource.id,
      'type' => resource.type,
      'start_node' => resource.start_node,
      'end_node' => resource.end_node,
      'properties' => expected_properties
    }}

    it_behaves_like 'a json serializer' do
      let(:expected_properties_object) { resource.properties }
      let(:expected_properties_json) {
        ActiveModel::Serializer.serializer_for(expected_properties_object).new(
          expected_properties_object
        ).to_json
      }
      let(:expected_properties) { JSON.parse(expected_properties_json) }
      it { is_expected.to include(expected_attributes) }
    end
  end

  context 'restricted' do
    let(:resource) {
      res = ProvenanceGraphRelationship.new(relationship)
      res.restricted = true
      res
    }
    let(:expected_attributes) {{
      'id' => resource.id,
      'type' => resource.type,
      'start_node' => resource.start_node,
      'end_node' => resource.end_node,
      'properties' => nil
    }}

    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_attributes) }
    end
  end
end
