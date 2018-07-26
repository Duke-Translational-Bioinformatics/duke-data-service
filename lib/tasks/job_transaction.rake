namespace :job_transaction do
  namespace :clean_up do
    desc 'Removes completed JobTransactions older than a month'
    task completed: :environment do
      if oldest = JobTransaction.oldest_completed_at
        months_ago = ((Time.now - oldest) / 1.month).floor
        if months_ago > 0
          months_ago.downto(1).each do |m|
            del_num = JobTransaction.delete_all_complete_by_request_id(created_before: Time.now - m.months)
            puts "Deleted #{del_num} from #{m} #{'month'.pluralize(m)} ago."
          end
        else
          puts "No completed JobTransactions older than 1 month found."
        end
      else
        puts "No completed JobTransactions found."
      end
    end
  end
end
