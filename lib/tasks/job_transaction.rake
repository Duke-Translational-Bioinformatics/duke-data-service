namespace :job_transaction do
  desc 'Removes completed JobTransactions older than a month'
  task clean_up: :environment do
  end
end
