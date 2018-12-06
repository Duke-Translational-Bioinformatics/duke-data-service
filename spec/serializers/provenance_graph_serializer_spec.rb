require 'rails_helper'

RSpec.describe ProvenanceGraphSerializer, type: :serializer do
  shared_examples 'a ProvenanceGraphSerializer' do |expected_object_node_syms:, expected_object_relationship_syms:|
    include_context 'performs enqueued jobs', only: GraphPersistenceJob
    let(:expected_object_nodes) { expected_object_node_syms.map{|enodesym| send(enodesym) }.flatten }
    let(:expected_object_relationships) { expected_object_relationship_syms.map{|ersym| send(ersym) }.flatten }

    it_behaves_like 'a has_many association with', :nodes, ProvenanceGraphNodeSerializer
    it_behaves_like 'a has_many association with', :relationships, ProvenanceGraphRelationshipSerializer

    it_behaves_like 'a json serializer' do
      it 'should have expected keys and values' do
        is_expected.to have_key('nodes')
        is_expected.to have_key('relationships')
        expected_nodes = expected_object_nodes.map{|enode|
          g = ProvenanceGraphNode.new(enode.graph_node)
          JSON.parse(ProvenanceGraphNodeSerializer.new(g).to_json)
        }.flatten
        expect(subject["nodes"]).to match_array(expected_nodes)

        expected_relationships = expected_object_relationships.map{|expected_object_relationship|
          expected_relationship = ProvenanceGraphRelationship.new(expected_object_relationship.graph_relation)
          JSON.parse(
            ProvenanceGraphRelationshipSerializer.new(expected_relationship).to_json
          )
        }.flatten
        expect(subject["relationships"]).to match_array(expected_relationships)
      end
    end
  end

  include_context 'mock all Uploads StorageProvider'
  let(:policy_scope) { Proc.new {|scope| scope } }

  context 'SearchProvenanceGraph' do
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
    let(:resource) {
      SearchProvenanceGraph.new(focus: focus, policy_scope: policy_scope)
    }

    it_behaves_like 'a ProvenanceGraphSerializer', expected_object_node_syms: [:focus, :activity],
      expected_object_relationship_syms: [:activity_used_focus]
  end

  context 'OriginProvenanceGraph' do
    # (fv1ga)-[generated]->(fv1)
    let!(:fv1) { FactoryBot.create(:file_version, label: "FV1") }
    let!(:fv1ga) { FactoryBot.create(:activity, name: "FV1GA") }
    let!(:fv1ga_generated_fv1) {
      FactoryBot.create(:generated_by_activity_prov_relation,
        relatable_from: fv1,
        relatable_to: fv1ga
      )
    }
    let!(:fv1_derived_from) { FactoryBot.create(:file_version, label: "FV1_DERIVED_FROM") }
    let!(:fv1_derived_from_fv1_derived_from) {
      FactoryBot.create(:derived_from_file_version_prov_relation,
        relatable_to: fv1_derived_from,
        relatable_from: fv1
      )
    }

    let!(:file_versions) { [ {id: fv1.id} ] }
    let(:resource) {
      OriginProvenanceGraph.new(
        file_versions: file_versions,
        policy_scope: policy_scope
      )
    }
    it_behaves_like 'a ProvenanceGraphSerializer', expected_object_node_syms: [:fv1, :fv1ga, :fv1_derived_from],
      expected_object_relationship_syms: [:fv1ga_generated_fv1, :fv1_derived_from_fv1_derived_from]
  end
end
