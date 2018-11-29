require 'rails_helper'

RSpec.describe ProvenanceGraphNodeSerializer, type: :serializer do
  include_context 'mock all Uploads StorageProvider'
  include_context 'performs enqueued jobs', only: GraphPersistenceJob
  let!(:focus) {
    FactoryBot.create(:file_version, label: "FOCUS")
  }
  let(:node) { focus.graph_node }

  context 'not restricted' do
    let(:resource) { ProvenanceGraphNode.new(node)    }
    let(:expected_attributes) {{
      'id' => resource.id,
      'labels' => resource.labels,
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
      res = ProvenanceGraphNode.new(node)
      res.restricted = true
      res
    }
    let(:expected_attributes) {{
      'id' => resource.id,
      'labels' => resource.labels,
      'properties' => { 'id' => node.model_id,
                        'kind' => node.model_kind,
                        'is_deleted' => focus.is_deleted}
    }}

    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_attributes) }
      it 'should not have unexpected keys' do
        ["name","label","created_at","updated_at","upload","audit"].each do |unexpected_key|
          expect(subject["properties"]).not_to have_key(unexpected_key)
        end
      end
    end
  end
end
