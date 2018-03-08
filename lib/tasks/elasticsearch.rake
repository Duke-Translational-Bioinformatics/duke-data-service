namespace :elasticsearch do
  namespace :index do
    desc "creates indices for all indexed models (in optional ENV[TARGET_URL])"
    task create: :environment do
      Rails.logger.level = 3
      if ENV['TARGET_URL']
        ElasticsearchHandler.new(verbose: true).create_indices(Elasticsearch::Client.new url: ENV['TARGET_URL'])
      else
        ElasticsearchHandler.new(verbose: true).create_indices
      end
    end #create

    desc "indexes all documents"
    task index_documents: :environment do
      Rails.logger.level = 3
      ElasticsearchHandler.new(verbose: true).index_documents
    end

    desc "drops indices for all indexed models (in optional ENV[TARGET_URL])"
    task drop: :environment do
      Rails.logger.level = 3
      if ENV['TARGET_URL']
        ElasticsearchHandler.new(verbose: true).drop_indices(Elasticsearch::Client.new url: ENV['TARGET_URL'])
      else
        ElasticsearchHandler.new(verbose: true).drop_indices
      end
    end #drop

    desc "drop create and index all documents for all indexed models if ENV[RECREATE_SEARCH_MAPPINGS] is true."
    task rebuild: :environment do
      if ENV["RECREATE_SEARCH_MAPPINGS"]
        Rails.logger.level = 3
        handler = ElasticsearchHandler.new(verbose: true)
        handler.drop_indices
        handler.create_indices
        handler.index_documents
        puts "mappings rebuilt"
      else
        $stderr.puts "ENV[RECREATE_SEARCH_MAPPINGS] false"
      end
    end #rebuild

    desc "attempt smart_reindex of all indexed models"
    task smart_reindex: :environment do
      Rails.logger.level = 3
      info = ElasticsearchHandler.new(verbose: true).smart_reindex_indices
      info[:skipped].each do |skipped_index|
        $stderr.puts "#{skipped_index} index exists, nothing more to do"
      end

      info[:reindexed].keys.each do |indexed_model|
        $stderr.puts "index for #{indexed_model} reindexed from #{info[:reindexed][indexed_model][:from]} to #{info[:reindexed][indexed_model][:to]}"
      end

      info[:migration_version_mismatch].keys.each do |indexed_model|
        $stderr.puts "#{indexed_model} #{info[:migration_version_mismatch][indexed_model][:from]} migration_version does not match #{info[:migration_version_mismatch][indexed_model][:to]}"
      end

      info[:missing_aliases].each do |missing_alias|
        $stderr.puts "#{missing_alias} alias does not exist!"
      end

      info[:has_errors].each do |indexed_model|
        $stderr.puts "fast reindex of #{indexed_model} has errors, leaving indices in place"
      end
    end

    desc "fast reindex ENV[SOURCE_INDEX] to (optional ENV[TARGET_URL]) ENV[TARGET_INDEX]"
    task fast_reindex: :environment do
      Rails.logger.level = 3
      if ENV['SOURCE_INDEX'] && ENV['TARGET_INDEX']
        source_client = Elasticsearch::Model.client
        target_client = nil
        if ENV['TARGET_URL']
          target_client = Elasticsearch::Client.new url: ENV['TARGET_URL']
        else
          target_client = source_client
        end

        eh = ElasticsearchHandler.new(verbose: true)
        trys = 5
        current_try = 1
        restart = false
        while current_try < trys
          begin
            eh.fast_reindex source_client, ENV['SOURCE_INDEX'], target_client, ENV['TARGET_INDEX'], restart
            current_try = trys
          rescue Elasticsearch::Transport::Transport::Errors::GatewayTimeout
            current_try = current_try + 1
            restart = true
          end
        end

        if eh.has_errors
          $stderr.puts "errors occurred"
        else
          $stderr.puts "reindex complete"
        end
      else
        $stderr.puts "ENV[SOURCE_INDEX] and ENV[TARGET_INDEX] are required"
      end
    end
  end
end
