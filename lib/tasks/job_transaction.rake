namespace :job_transaction do
  desc 'Removes completed JobTransactions older than a month'
  task clean_up: :environment do
    if oldest = JobTransaction.oldest_completed_at
      months_ago = ((Time.now - oldest) / 1.month).floor
      if months_ago > 0
        months_ago.downto(1).each do |m|
          JobTransaction.delete_all_complete_by_request_id
          puts "Delete from #{m} #{'month'.pluralize(m)} ago."
        end
      else
        puts "No completed transactions older than 1 month found."
      end
    else
      puts "No completed JobTransactions found."
    end
  end
end
