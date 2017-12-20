class ElasticsearchHandler
  attr_reader :verbose
  def initialize(verbose:false)
    @verbose = verbose
  end

  def create_indices(client=Elasticsearch::Model.client)
    drop_indices(client)
    FolderFilesResponse.indexed_models.each do |indexed_model|
      client.indices.create(
        index: indexed_model.versioned_index_name,
        body: {
          settings: indexed_model.settings.to_hash,
          mappings: indexed_model.mappings.to_hash
        }
      )

      if client.indices.exists_alias? name: indexed_model.index_name
        client.indices.get_alias(name: indexed_model.index_name).keys.each do |aliased_index|
          $stderr.puts "consider deleting index #{aliased_index}" if @verbose
          client.indices.delete_alias index: aliased_index, name: indexed_model.index_name
        end
      end
      client.indices.put_alias index: indexed_model.versioned_index_name, name: indexed_model.index_name
    end
  end

  def index_documents
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
          bulk_response = Elasticsearch::Model.client.bulk body: current_batch
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

  def smart_reindex_indices
    client = Elasticsearch::Model.client
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

            if fast_reindex(client, aliased_index_name, client, indexed_model.versioned_index_name)
              client.indices.delete_alias index: aliased_index_name, name: indexed_model.index_name
              client.indices.put_alias index: indexed_model.versioned_index_name, name: indexed_model.index_name
              client.indices.delete index: aliased_index_name
              reindex_information[:reindexed]["#{indexed_model}"] = {from: aliased_index_name, to: indexed_model.versioned_index_name}
            else
              reindex_information[:has_errors] << "#{indexed_model}"
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

  def start_scroll(client, index, scroll:'1m', body:{sort: ['_doc']})
    client.search index: index, scroll: scroll, body: body
  end

  def next_scroll(client, scroll_id, scroll:'5m')
    client.scroll(scroll_id: scroll_id, scroll: scroll)
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

  def fast_reindex(source_client, source_index, target_client, target_index)
    has_errors = false
    r = start_scroll(source_client, source_index)
    bulk_response = send_batch(
      target_client,
      batch_from_search(target_index, r)
    )
    if bulk_response["errors"]
      has_errors = true
      if @verbose
        $stderr.puts "errors:"
        $stderr.puts bulk_response["items"].select {|item|
          item["index"]["status"] >= 400
        }.map {|i|
          i["index"]["_id"]
        }.to_json
      end
    end

    while r = next_scroll(source_client, r['_scroll_id']) do
      break if r['hits']['hits'].empty?
      bulk_response = send_batch(
        target_client, batch_from_search(target_index, r)
      )
      if bulk_response["errors"]
        has_errors = true
        if @verbose
          $stderr.puts "errors:"
          $stderr.puts bulk_response["items"].select {|item|
            item["index"]["status"] >= 400
          }.map {|i|
            i["index"]["_id"]
          }.to_json
        end
      end
    end
    !has_errors
  end
end
