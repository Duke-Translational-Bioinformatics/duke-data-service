# ElasticsearchHandler
#  Handler encapsulating many useful Elasticsearch Cluster activities
#
#  Usage:
#  ElasticsearchHandler.new
#    verbose is false, nothing will be printed to stderr
#
#  ElasticsearchHandler.new(true)
#    verbose is true, some methods will print information to stderr
#
class ElasticsearchHandler
  attr_reader :verbose, :has_errors, :current_scroll_id
  def initialize(verbose:false)
    @verbose = verbose
    @has_errors = false
  end

  # create_indices
  #
  # arguments:
  #   client: optional. Must be an instance of
  #           Elasticsearch::Transport::Client
  #           default: Elasticsearch::Model.client
  #
  # For each SearchableModel:
  #   - creates its versioned_index_name index if it doesnt already exist
  #   - creates an alias from its index_name to the versioned_index_name index.
  #     if the alias exists, and it is aliase to a previous versioned_index_name
  #     it will delete the alias, but not the previous versioned_index_name,
  #     and attach the alias to the new versioned_index_name
  def create_indices(client=Elasticsearch::Model.client)
    FolderFilesResponse.indexed_models.each do |indexed_model|
      unless client.indices.exists? index: indexed_model.versioned_index_name
        client.indices.create(
          index: indexed_model.versioned_index_name,
          body: {
            settings: indexed_model.settings.to_hash,
            mappings: indexed_model.mappings.to_hash
          }
        )
      end
      if client.indices.exists_alias? name: indexed_model.index_name
        client.indices.get_alias(name: indexed_model.index_name).keys.each do |aliased_index|
          $stderr.puts "consider deleting index #{aliased_index}" if @verbose
          client.indices.delete_alias index: aliased_index, name: indexed_model.index_name
        end
      end
      client.indices.put_alias index: indexed_model.versioned_index_name, name: indexed_model.index_name
    end
  end

  # index_documents
  #
  # arguments:
  #   client: optional. Must be an instance of
  #           Elasticsearch::Transport::Client
  #           default: Elasticsearch::Model.client
  #   Very slow method of loading batches of 500 documents from ActiveRecord
  #   to elasticsearch.
  #  TODO refactor
  def index_documents(client=Elasticsearch::Model.client)
    batch_size = 500
    FolderFilesResponse.indexed_models.each do |indexed_model|
      indexed_model.paginates_per batch_size
      (1 .. indexed_model.page.total_pages).each do |page_num|
        current_batch = indexed_model
          .page(page_num)
          .map { |f|
            { index: {
              _index: indexed_model.versioned_index_name,
              _type: f.__elasticsearch__.document_type,
              _id: f.__elasticsearch__.id,
              data: f.__elasticsearch__.as_indexed_json }
            }
        }
        trys = 0
        error_ids = []
        while trys < 5
          bulk_response = client.bulk body: current_batch
          if bulk_response["errors"]
            trys += 1
            error_ids = bulk_response["items"].select {|item|
              item["index"]["status"] >= 400
            }.map {|i|
              i["index"]["_id"]
            }
            current_batch = current_batch.select {|b| error_ids.include? b[:index][:_id] }
          else
            trys = 5
            error_ids = []
          end
        end
        if @verbose
          unless error_ids.empty?
            $stderr.puts "page #{page_num} Ids Not Loaded after #{trys} tries:"
            $stderr.puts error_ids.join(',')
          end
          $stderr.print "+" * (current_batch.length - error_ids.length)
        end
      end
    end
  end

  def drop_indices(client=Elasticsearch::Model.client)
    client.indices.delete index: '_all'
  end

  # smart_reindex_indices
  #
  # Assumes that indices have been created using ElasticsearchHandler #create_indices
  # using the versioned_index_name indices.
  # For each Searchable Model
  #  - checks if the versioned_index_name exists. If so, skips this model
  #  - checks if the alias exists. Reports missing aliases if missing
  #  - checks index of alias, if its migration_version does not match the current
  #    Model migration_version, reports migration_version_mismatch
  #  - attempts fast_reindex if migration_version matches. If error occurrs, reports has_erros
  #  - if errrors do not occur, drops old alias, creates alias index_name -> versioned_index_name
  #    drops old version index, and reports reindexed inforamtion
  def smart_reindex_indices(client=Elasticsearch::Model.client)
    reindex_information = {
      skipped: [],
      reindexed: {},
      migration_version_mismatch: {},
      missing_aliases: [],
      has_errors: []
    }
    FolderFilesResponse.indexed_models.each do |indexed_model|
      if client.indices.exists? index: indexed_model.versioned_index_name
        reindex_information[:skipped] << "#{indexed_model.versioned_index_name}"
      else
        if client.indices.exists_alias? name: indexed_model.index_name
          existing_alias = client.indices.get_alias name: indexed_model.index_name
          aliased_index_name = existing_alias.keys.first
          if aliased_index_name.match indexed_model.migration_version
            client.indices.create(
              index: indexed_model.versioned_index_name,
              body: {
                settings: indexed_model.settings.to_hash,
                mappings: indexed_model.mappings.to_hash
              }
            )

            restart = false
            trys = 5
            current_try = 1
            while current_try < trys do
              begin
                fast_reindex(client, aliased_index_name, client, indexed_model.versioned_index_name, restart)
                current_try = trys
              rescue Elasticsearch::Transport::Transport::Errors::GatewayTimeout
                restart = true
                current_try = current_try + 1
              end
            end
            if @has_errors
              reindex_information[:has_errors] << "#{indexed_model}"
            else
              client.indices.delete_alias index: aliased_index_name, name: indexed_model.index_name
              client.indices.put_alias index: indexed_model.versioned_index_name, name: indexed_model.index_name
              client.indices.delete index: aliased_index_name
              reindex_information[:reindexed]["#{indexed_model}"] = {from: aliased_index_name, to: indexed_model.versioned_index_name}
            end
          else
            reindex_information[:migration_version_mismatch]["#{indexed_model}"] = {from: aliased_index_name, to: indexed_model.migration_version}
          end
        else
          reindex_information[:missing_aliases] << "#{indexed_model.index_name}"
        end
      end
    end
    reindex_information
  end

  def start_scroll(client, index, scroll:'1m', body:{size: 10000, sort: ['_doc']})
    resp = client.search index: index, scroll: scroll, body: body
    @current_scroll_id = resp['_scroll_id']
    resp
  end

  def next_scroll(client, scroll:'5m')
    resp = client.scroll(scroll_id: @current_scroll_id, scroll: scroll)
    @current_scroll_id = resp['_scroll_id']
    resp
  end

  def send_batch(client, batch)
    client.bulk body: batch
  end

  def batch_from_search(index, search_response)
    search_response['hits']['hits'].map {|hit|
      {
        index: {
          _index: index,
          _type: hit['_type'],
          _id: hit['_id'],
          data: hit['_source']
        }
      }
    }
  end

  # fast_reindex
  #
  # takes a source elasticsearch client, and target elasticsearch client
  #  (can be the same client), source_index, and target_index, and
  #  uses the scroll method to transfer existing documents from the
  #  source_client:source_index -> target_client:target_index
  #  This can be used to:
  #    - fast reindex of one index to another index on the same cluster
  #    - transfer data from one elasticsearch cluster to another
  def fast_reindex(source_client, source_index, target_client, target_index, restart=false)
    if restart
      scroll_result = next_scroll(source_client)
    else
      scroll_result = start_scroll(source_client, source_index)
    end

    while !scroll_result['hits']['hits'].empty? do
      bulk_response = send_batch(
        target_client, batch_from_search(target_index, scroll_result)
      )
      check_batch_errors bulk_response
      scroll_result = next_scroll(source_client)
    end
  end

  def check_batch_errors(bulk_response)
    if bulk_response["errors"]
      if @verbose
        $stderr.puts "errors:"
        $stderr.puts bulk_response["items"].select {|item|
          item["index"]["status"] >= 400
        }.map {|i|
          i["index"]["_id"]
        }.to_json
      end
      @has_errors = true
    end
  end
end
