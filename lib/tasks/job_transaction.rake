namespace :job_transaction do
  namespace :clean_up do
    desc 'Removes completed JobTransactions older than a month'
    task completed: :environment do
      if oldest = JobTransaction.oldest_completed_at
        months_ago = ((Time.now - oldest) / 1.month).floor
        if months_ago > 0
          months_ago.downto(1).each do |m|
            del_num = JobTransaction.delete_all_complete_jobs(created_before: Time.now - m.months)
            puts "Deleted #{del_num} JobTransactions for completed jobs from #{m} #{'month'.pluralize(m)} ago."
          end
        else
          puts "No completed JobTransactions older than 1 month found."
        end
      else
        puts "No completed JobTransactions found."
      end
    end

    desc 'Removes orphan JobTransactions older than a month'
    task orphans: :environment do
      batch_size = ENV['BATCH_SIZE']&.to_i || 50000
      if oldest = JobTransaction.oldest_orphan_created_at
        months_ago = ((Time.now - oldest) / 1.month).floor
        if months_ago > 0
          months_ago.downto(1).each do |m|
            total_del_num = 0
            loop do
              del_num = JobTransaction.delete_all_orphans(created_before: Time.now - m.months, limit: batch_size)
              print '-'
              total_del_num += del_num
              break if del_num < batch_size
            end
            puts '-'
            puts "Deleted #{total_del_num} orphan JobTransactions from #{m} #{'month'.pluralize(m)} ago."
          end
        else
          puts "No orphan JobTransactions older than 1 month found."
        end
      else
        puts "No orphan JobTransactions found."
      end
    end

    desc 'Removes logical orphan JobTransactions older than a month'
    task logical_orphans: :environment do
      if oldest = JobTransaction.oldest_logical_orphan_created_at
        months_ago = ((Time.now - oldest) / 1.month).floor
        if months_ago > 0
          months_ago.downto(1).each do |m|
            del_num = JobTransaction.delete_all_logical_orphans(created_before: Time.now - m.months)
            puts "Deleted #{del_num} logical orphan JobTransactions from #{m} #{'month'.pluralize(m)} ago."
          end
        else
          puts "No logical orphan JobTransactions older than 1 month found."
        end
      else
        puts "No logical orphan JobTransactions found."
      end
    end

    desc 'Invoke all job_transaction:clean_up tasks'
    task :all => %w[job_transaction:clean_up:completed job_transaction:clean_up:orphans job_transaction:clean_up:logical_orphans]
  end
end
