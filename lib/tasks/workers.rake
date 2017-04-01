require 'sneakers/runner'
namespace :workers do
  JobsRunner.workers_registry.each do |worker_key, worker_class|
    namespace worker_key do
      desc "run an #{worker_class}"
      task run: :environment do
        JobsRunner.new(worker_class).run
      end
    end
  end

  namespace :all do
    desc 'run all jobs'
    task run: :environment do
      skip_workers = (ENV['WORKERS_ALL_RUN_EXCEPT']||'').gsub(' ','').split(',')
      JobsRunner.all(except: skip_workers).run
    end
  end
end
