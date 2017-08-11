Rails.application.config.max_children_per_job = ENV['MAX_CHILDREN_PER_JOB'] ? ENV['MAX_CHILDREN_PER_JOB'].to_i : 100
