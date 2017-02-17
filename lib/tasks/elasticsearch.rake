def create_indices
  current_indices = DataFile.__elasticsearch__.client.cat.indices
  ElasticsearchResponse.indexed_models.each do |indexed_model|
    if current_indices.include? indexed_model.index_name
      indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
    end
    indexed_model.__elasticsearch__.client.indices.create(
      index: indexed_model.index_name,
      body: {
        settings: indexed_model.settings.to_hash,
        mappings: indexed_model.mappings.to_hash
      }
    )
  end
  # property mappings
  MetaProperty.all.each do |mp|
    mp.create_mapping
  end
end

def index_batch(current_batch)

  []
end

def index_documents
  batch_size = 500
  ElasticsearchResponse.indexed_models.each do |indexed_model|
    indexed_model.paginates_per batch_size
    (1 .. indexed_model.page.total_pages).each do |page_num|
      current_batch = indexed_model
        .page(page_num)
        .map { |f|
          { index: {
            _index: f.__elasticsearch__.index_name,
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
      unless error_ids.empty?
        $stderr.puts "page #{page_num} Ids Not Loaded after #{trys} tries:"
        $stderr.puts error_ids.join(',')
      end
      $stderr.print "+" * (current_batch.length - error_ids.length)
    end
  end
end

def drop_indices
  current_indices = DataFile.__elasticsearch__.client.cat.indices
  ElasticsearchResponse.indexed_models.each do |indexed_model|
    if current_indices.include? indexed_model.index_name
      indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
    end
  end
end

namespace :elasticsearch do
  namespace :index do
    desc "creates indices for all indexed models"
    task create: :environment do
      Rails.logger.level = 3
      create_indices
    end #create

    desc "indexes all documents"
    task index_documents: :environment do
      Rails.logger.level = 3
      index_documents
    end

    desc "drops indices for all indexed models"
    task drop: :environment do
      Rails.logger.level = 3
      drop_indices
    end #drop

    desc "drop create and index all documents for all indexed models if ENV[RECREATE_SEARCH_MAPPINGS] is true."
    task rebuild: :environment do
      if ENV["RECREATE_SEARCH_MAPPINGS"]
        Rails.logger.level = 3
        drop_indices
        create_indices
        index_documents
        puts "mappings rebuilt"
      else
        $stderr.puts "ENV[RECREATE_SEARCH_MAPPINGS] false"
      end
    end #rebuild
  end
end
