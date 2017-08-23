module DDS
  module V1
    class SearchAPI < Grape::API
      helpers PaginationParams

      desc 'Search Provenance' do
        detail 'Search Provenance related to a start_node by max_hops degrees of separation (default inifinite)'
        named 'Search Provenance'
        failure [
          [200, 'This will never happen'],
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
      post '/search/provenance', root: 'graph', serializer: ProvenanceGraphSerializer do
        authenticate!
        prov_tags = declared(params, include_missing: false)
        max_hops = prov_tags[:max_hops]
        start_node_kind = KindnessFactory.by_kind(prov_tags[:start_node][:kind])
        start_node = start_node_kind.find(prov_tags[:start_node][:id])
        authorize start_node, :show?
        SearchProvenanceGraph.new(
          focus: start_node,
          max_hops: max_hops,
          policy_scope: method(:policy_scope))
      end

      desc 'Search Provenance wasGeneratedBy' do
        detail 'This is a targeted query that navigates "up" the provenance chain for a file version to see how it was generated (i.e. by what activity) and from what source file versions. Given a list of file versions, this action perform the following query for each file version: 1. Gets the generating activity. 2. For the generating activity, gets the list of wasGeneratedBy and used file versions. A graph structure of the unique nodes and relationships is returned.'
        named 'Search Provenance wasGeneratedBy'
        failure [
          [200, 'This will never happen'],
          [201, 'Success'],
          [401, 'Unauthorized']
        ]
      end
      params do
        requires :file_versions, type: Array, desc: 'The list of file versions (i.e. dds-file-version)' do
          requires :id, type: String, desc: 'The unique file version id.'
        end
      end
      post '/search/provenance/origin', root: 'graph', serializer: ProvenanceGraphSerializer do
        authenticate!
        prov_params = declared(params, include_missing: false)
        OriginProvenanceGraph.new(
          file_versions: prov_params[:file_versions],
          policy_scope: method(:policy_scope))
      end

      desc 'Search Objects' do
        detail 'This endpoint is scheduled to be removed very soon. You should use /search/folders_files instead.'
        named 'Deprecated!'
        failure [
          [200, 'This will never happen'],
          [201, 'Success'],
          [401, 'Unauthorized'],
          [404, 'One or more included kinds is not supported, or not indexed']
        ]
      end
      params do
        requires :include_kinds, type: Array[String], desc: 'The kind of objects (i.e. Elasticsearch document types) to include in the search; can include folders and/or files (i.e. dds-folder, dds-file)'
        requires :search_query, type: Hash, desc: 'The Elasticsearch query criteria (i.e. Query DSL)'
      end
      post '/search', root: false do
        authenticate!
        search_params = declared(params, include_missing: false)
        indices = []
        search_params[:include_kinds].each do |included_kind|
          kinded_model = KindnessFactory.kind_map[included_kind]
          raise NameError.new("object_kind #{included_kind} Not Supported") unless kinded_model
          indices << kinded_model
        end
        DeprecatedElasticsearchResponse.new(
          query: search_params[:search_query],
          indices: indices,
          policy_scope: method(:policy_scope)
        )
      end

      desc 'Search Folders and Files' do
        detail 'This endpoint allows searches of folders and files with a variety of query, filter, and post_filter features'
        named 'search folders_files'
        failure [
          [200, 'This will never happen'],
          [201, 'Success'],
          [401, 'Unauthorized'],
          [400, 'Invalid value specified for query_string.fields'],
          [400, 'Invalid "{key: value}" specified for filters[].object'],
          [400, 'Required fields - aggs[].field, aggs[].name must be specified'],
          [400, 'Invalid value specified for aggs[].field'],
          [400, 'Invalid size specified for aggs[].size - out of range'],
          [400, 'Invalid "{key: value}" specified for post_filters[].object']
        ]
      end
      params do
        optional :query_string, type: Hash do
          optional :query, type: String, desc: "The string fragment (phrase) to search for in query_string.fields. Required if query_string.fields are submitted."
          optional :fields, type: Array, desc: "List of text fields to search; valid options are name and tags.label.  If not specified, defaults to all options. Requires query_string.query."
        end
        optional :filters, type: Array, desc: 'List of boolean search objects (predicates) that are joined together by AND operator, represented as key: value pairs' do
          optional :kind , type: Array, desc: 'Limit search context to list of kinds; valid options are dds-folder and dds-file - requires a set of comma-delimited kinds like so: {"kind": ["dds-file"]}. If not specified, defaults to all options.'
          optional 'project.id', type: Array, desc: 'Limit search context to list of projects; requires a set of comma-delimited ids like so: {"project.id": ["345e...", "2e45..."]}. Filters out projects to which the user is not allowed access. If not specified, defaults to projects in which the current user has view permission.'
        end
        optional :aggs, type: Array, desc: 'List of aggs (aggregates) that should be computed.' do
          optional :field, type: String, desc: 'The field for which you want to compute agg; valid options are project.name and tags.label. Required if one or more aggs are submitted.'
          optional :name, type: String, desc: 'The name to give the group of computed agg buckets for the field. Required if one or more aggs are submitted.'
          optional :size, type: Integer, desc: 'The number of agg buckets to return with the results; defaults to the top 20 and cannot be greater than 50.'
        end
        optional :post_filters, type: Array, desc: 'List of boolean search objects (predicates) that are joined together by the AND operator - they are represented as key: value pairs' do
          optional 'project.name', type: Array, desc: 'List of project names; requires a set of comma-delimited names like so: {"project.name": ["Big Mouse", "BD2K"]}.'
          optional 'tags.label', type: Array, desc: 'List of tags; requires a set of comma-delimited tag labels like so: {"tags.label": ["sequencing", "DNA"]}.'
        end
        use :pagination
      end
      rescue_from ArgumentError do |e|
        error_json = {
          "error" => "400",
          "reason" => e.message,
          "suggestion" => "Please supply the correct argument"
        }
        error!(error_json, 400)
      end
      post '/search/folders_files', root: false do
        authenticate!
        search_params = declared(params, include_missing: false)
        project_filter_exists = false

        search_params[:filters] ||= []
        search_params[:filters].each do |f|
          if f.has_key? 'project.id'
            filtered = policy_scope(Project).where(is_deleted: false, id: f['project.id']).all.to_a.map{|p| p.id}
            raise Pundit::NotAuthorizedError, "You do not have access to view one or more projects provided in filters[] project.id list" unless (f['project.id'] - filtered).empty?
            project_filter_exists = true
          end
        end
        unless project_filter_exists
          search_params[:filters] << {'project.id' => policy_scope(Project).where(is_deleted: false).all.map {|p| p.id}}
        end

        f = FolderFilesResponse.new
          .filter(search_params[:filters])
          .query(search_params[:query_string])
          .aggregate(search_params[:aggs])
          .post_filter(search_params[:post_filters])
          .search
        paginate f
      end
    end
  end
end
