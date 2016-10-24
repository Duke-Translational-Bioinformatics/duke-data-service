require 'rails_helper'

RSpec.describe ProvenanceGraphNodeSerializer, type: :serializer do
  let!(:focus) {
    FactoryGirl.create(:file_version, label: "FOCUS")
  }
  let(:node) { focus.graph_node }

  context 'not restricted' do
    let(:resource) { ProvenanceGraphNode.new(node)    }

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

  context 'restricted' do
    let(:resource) {
      res = ProvenanceGraphNode.new(node)
      res.restricted = true
      res
    }

    it_behaves_like 'a json serializer' do
      it 'should have expected keys and values' do
        is_expected.to have_key('id')
        is_expected.to have_key('labels')
        is_expected.to have_key('properties')
        expect(subject["id"]).to eq(resource.id)
        expect(subject["labels"]).to eq(resource.labels)
        expect(subject["properties"]).not_to be_nil
        expect(subject["properties"]).to have_key('id')
        expect(subject["properties"]["id"]).to eq(node.model_id)
        expect(subject["properties"]).to have_key('kind')
        expect(subject["properties"]["kind"]).to eq(node.model_kind)
        expect(subject["properties"]).to have_key('is_deleted')
        if focus.is_deleted
          expect(subject["properties"]["is_deleted"]).to be true
        else
          expect(subject["properties"]["is_deleted"]).to be false
        end
        ["name","label","created_at","updated_at","upload","audit"].each do |unexpected_key|
          expect(subject["properties"]).not_to have_key(unexpected_key)
        end
      end
    end
  end
end
