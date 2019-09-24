class FolderFilesResponse
  include ActiveModel::Model
  include ActiveModel::Serialization
  attr_reader :elastic_response

  @@all_indices = [DataFile,Folder,Activity]
  def self.indexed_models
    @@all_indices
  end

  @@supported_query_string_fields = ['name', 'tags.label']
  def self.supported_query_string_fields
    @@supported_query_string_fields
  end

  @@supported_filter_keys = ['kind', 'project.id']
  def self.supported_filter_keys
    @@supported_filter_keys
  end

  @@supported_filter_kinds = ['dds-file', 'dds-folder']
  def self.supported_filter_kinds
    @@supported_filter_kinds
  end

  @@supported_agg_fields = ['project.name', 'tags.label']
  def self.supported_agg_fields
    @@supported_agg_fields
  end

  @@default_agg_size = 20
  def self.default_agg_size
    @@default_agg_size
  end

  def initialize
    @filters = []
    @query_string = nil
    @aggs = nil
    @post_filters = nil
  end

  def filter(filters=nil)
    @filters = filters
    self
  end

  def query(query_string=nil)
    @query_string = query_string
    self
  end

  def post_filter(post_filters=nil)
    @post_filters = post_filters
    self
  end

  def aggregate(aggs=nil)
    @aggs = aggs
    self
  end

  def search
    validate_filters
    validate_query_string
    validate_aggs
    validate_post_filters

    query = hide_logically_deleted build_query
    search_definition(query)
    self
  end

  def results
    @elastic_response.results.map{|r| r["_source"]}
  end

  def aggs
    @elastic_response.response["aggregations"]
  end

  #pagination
  delegate :total_count, to: :elastic_response
  delegate :total_pages, to: :elastic_response
  delegate :total, to: :elastic_response
  delegate :limit_value, to: :elastic_response
  delegate :current_page, to: :elastic_response
  delegate :next_page, to: :elastic_response
  delegate :prev_page, to: :elastic_response

  def page(page)
    @elastic_response.page(page)
    self
  end

  def per(per)
    @elastic_response.per(per)
    self
  end

  def padding(padding)
    @elastic_response.padding(padding)
    self
  end

  private

  def validate_filters
    raise ArgumentError("filters must be a list") unless @filters.is_a? Array
    if @filters.nil? || @filters.empty?
      raise ArgumentError.new("project.id filter is required")
    end
    project_id_filter_seen = false
    kind_filter_seen = false
    @filters.each do |filter|
      filter.each do |key, filter_terms|
        raise ArgumentError.new("filters must be one of #{@@supported_filter_keys.join(', ')}") unless @@supported_filter_keys.include?(key)
        raise ArgumentError.new("filters[] value must be a list") unless filter_terms.is_a? Array

        if key == 'kind'
          raise ArgumentError.new('filters[] can have at most one project.id or kind entry') if kind_filter_seen
          filter_terms.each do |filter_term|
            raise ArgumentError.new("filters[] kind must be one of #{@@supported_filter_kinds.join(', ')}") unless @@supported_filter_kinds.include?(filter_term)
          end
          kind_filter_seen = true
        end
        if (key == 'project.id')
          raise ArgumentError.new('filters[] can have at most one project.id or kind entry') if project_id_filter_seen
          project_id_filter_seen = true
        end
      end
    end
    raise ArgumentError.new("filters[project.id] is required") unless project_id_filter_seen
  end

  def validate_aggs
    @aggs_fields = []
    if @aggs
      raise ArgumentError.new('aggs must be a list') unless @aggs.is_a? Array
      @aggs.each do |agg|
        raise ArgumentError.new("aggs[].field is required") unless agg.has_key?(:field)
        raise ArgumentError.new("aggs[].field must be one of #{@@supported_agg_fields.join(', ')}") unless @@supported_agg_fields.include?(agg[:field])
        raise ArgumentError.new("aggs[].name is required") unless agg.has_key?(:name)
        raise ArgumentError.new('aggs[].size must be at least 20 and at most 50') if agg.has_key?(:size) && agg[:size].to_i < 20
        raise ArgumentError.new('aggs[].size must be at least 20 and at most 50') if agg.has_key?(:size) && agg[:size].to_i > 50
        @aggs_fields << agg[:field]
      end
    end
  end

  def validate_query_string
    if @query_string && @query_string.has_key?(:fields)
      raise ArgumentError.new("query_string.fields is not allowed without query_string.query") unless @query_string.has_key?(:query)

      @query_string[:fields].each do |qf|
        raise ArgumentError.new("query_string.field must be one of #{@@supported_query_string_fields.join(', ')}") unless @@supported_query_string_fields.include?(qf)
      end
    end
  end

  def validate_post_filters
    if @post_filters
      raise ArgumentError.new("post_filters must be used with aggs") unless @aggs && !@aggs.empty?
      raise ArgumentError.new("post_filters must be a list") unless @post_filters.is_a? Array
      field_seen = {}
      @post_filters.each do |post_filter|
        key = post_filter.keys.first
        raise ArgumentError.new('post_filters[] can have at most one #{key} entry') if field_seen[key]
        raise ArgumentError.new("post_filters key must be one of #{@@supported_agg_fields.join(', ')}") unless @@supported_agg_fields.include?(key)
        raise ArgumentError.new("post_filters[#{key}] must be accompanied by aggs[].field #{key}") unless @aggs_fields.include?(key)
        field_seen[key] = true
      end
    end
  end

  def build_query
    filter_terms = []
    @filters.each do |filter|
      filter.each do |k,v|
        filter_terms << {terms: { "#{k}.raw" => v } }
      end
    end

    query = {
      query: {
        bool: {
          filter: {
            bool: {
              must: filter_terms
            }
          }
        }
      }
    }

    if @query_string
      if @query_string[:query].match(/\s/)
        query[:query][:bool][:must] = {
          query_string: {
            query: "*#{@query_string[:query]}* *#{@query_string[:query].gsub(/\s/,'* *')}*"
          }
        }
      else
        query[:query][:bool][:must] = {
          query_string: {
            query: "*#{@query_string[:query]}*"
          }
        }
      end

      if @query_string[:fields]
        query[:query][:bool][:must][:query_string][:fields] = @query_string[:fields]
      else
        query[:query][:bool][:must][:query_string][:fields] = @@supported_query_string_fields
      end
    end

    if @aggs
      query[:aggs] = {}
      @aggs.each do |agg|
        size = agg[:size] || @@default_agg_size
        query[:aggs][agg[:name]] = {
          terms: {
              field: "#{agg[:field]}.raw",
              size: size
           }
        }
      end
    end

    if @post_filters
      post_filter_terms = []

      @post_filters.each do |post_filter|
        post_filter.each do |field, terms|
          post_filter_terms << {terms: {"#{field}.raw" => terms}}
        end
      end

      query[:post_filter] = {
        bool: {
          must: post_filter_terms
        }
      }
    end

    query
  end

  def search_definition(query)
    @elastic_response = Elasticsearch::Model.search(query, @@all_indices)
  end

  private

  def hide_logically_deleted(query)
    # this may be turned into a context on the object in the future
    query[:query][:bool][:filter][:bool][:must_not] = {
      term: {"is_deleted" => {"value": "true"}}
    }
    query
  end
end
