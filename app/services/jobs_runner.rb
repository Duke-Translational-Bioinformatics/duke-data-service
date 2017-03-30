require 'sneakers/runner'

class JobsRunner
  def initialize(job_class_or_array)
    @job = job_class_or_array
  end

  def run
    Sneakers::Runner.new([@job]).run
  end
end
