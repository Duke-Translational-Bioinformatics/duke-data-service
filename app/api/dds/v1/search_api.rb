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
        authorize start_node, :show?
        ProvenanceGraph.new(
          focus: start_node,
          max_hops: max_hops,
          policy_scope: method(:policy_scope))
      end

      desc 'Search Objects' do
        detail 'Search for DDS objects using the elasticsearch query_dsl on supported kinds of objects'
        named 'Search Objects'
        failure [
          [200, 'Will never happen'],
          [201, 'Success'],
          [401, 'Unauthorized'],
          [404, 'one or more included kinds is not supported, or not indexed']
        ]
      end
      params do
        requires :included_kinds, type: Array, desc: 'The kind of objects (i.e. Elasticsearch document types) to include in the search; can include folders and/or files (i.e. dds-folder, dds-file)'
        requires :search_query, type: Hash, desc: 'The Elasticsearch query criteria (i.e. Query DSL)'
      end
      post '/search', root: false do
        authenticate!
        search_params = declared(params, include_missing: false)
        indices = []
        search_params[:included_kinds].each do |included_kind|
          kinded_model = KindnessFactory.kind_map[included_kind]
          raise NameError.new("object_kind #{included_kind} Not Supported") unless kinded_model
          indices << kinded_model
        end
        ElasticsearchResponse.new(
          query: search_params[:search_query],
          indices: indices,
          policy_scope: method(:policy_scope)
        )
      end
    end
  end
end
