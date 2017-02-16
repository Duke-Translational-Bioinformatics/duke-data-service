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
      Elasticsearch::Model.client.bulk body: current_batch
      $stderr.print "+" * current_batch.length
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
