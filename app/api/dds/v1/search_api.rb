module DDS
  module V1
    class SearchAPI < Grape::API
      desc 'Search Provenance' do
        detail 'Search Provenance related to a start_node by max_hops degrees of separation (default inifinite)'
        named 'Search Provenance'
        failure [
          [200, 'Will never happen'],
          [201, 'Success'],
          [401, 'Unauthorized'],
          [404, 'start_node or start_node kind does not exist']
        ]
      end
      params do
        requires :start_node, type: Hash do
          requires :kind, type: String, desc: "The kind of start_node"
          requires :id, type: String, desc: "The unique id of start_node"
        end
        optional :max_hops, type: Integer, desc: "Maximum number of degrees of seperation from start node (default infinite)"
      end
      post '/search/provenance', root: 'graph' do
        authenticate!
        prov_tags = declared(params, include_missing: false)
        max_hops = prov_tags[:max_hops]
        start_node_kind = KindnessFactory.by_kind(prov_tags[:start_node][:kind])
        start_node = start_node_kind.find(prov_tags[:start_node][:id])
        hide_logically_deleted start_node
        authorize start_node, :show?
        ProvenanceGraph.new(focus: start_node, max_hops: max_hops, policy_scope: method(:policy_scope))
      end
    end
  end
end
