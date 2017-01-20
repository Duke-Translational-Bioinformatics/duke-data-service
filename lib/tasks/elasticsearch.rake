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
  ElasticsearchResponse.indexed_models.each do |indexed_model|
    indexed_model.all.each do |im|
      im.__elasticsearch__.index_document
      $stderr.puts "+"
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
