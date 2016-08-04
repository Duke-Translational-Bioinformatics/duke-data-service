require 'rails_helper'

RSpec.describe ProvenanceGraphSerializer, type: :serializer do
  let(:policy_scope) { Proc.new {|scope| scope } }

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
  let(:resource) {
    ProvenanceGraph.new(focus: focus, policy_scope: policy_scope)
  }

  it_behaves_like 'a has_many association with', :nodes, ProvenanceGraphNodeSerializer
  it_behaves_like 'a has_many association with', :relationships, ProvenanceGraphRelationshipSerializer

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('nodes')
      is_expected.to have_key('relationships')
      expected_nodes = [focus, activity].map{|enode|
        g = ProvenanceGraphNode.new(enode.graph_node)
        g.properties = enode
        JSON.parse(ProvenanceGraphNodeSerializer.new(g).to_json)
      }.flatten

      expected_relationship = ProvenanceGraphRelationship.new(activity_used_focus.graph_relation)
      expected_relationship.properties = activity_used_focus

      expect(subject["nodes"]).to match_array(expected_nodes)
      expect(subject["relationships"]).to match_array([
        JSON.parse(
          ProvenanceGraphRelationshipSerializer.new(expected_relationship).to_json
        ) ] )
    end
  end
end
