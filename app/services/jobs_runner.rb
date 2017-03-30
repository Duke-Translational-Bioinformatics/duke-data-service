require 'sneakers/runner'

class JobsRunner
  def initialize(job_class_or_array)
    @jobs = [job_class_or_array].flatten
  end

  def run
    Sneakers::Runner.new(@jobs).run
  end
end
