#!/usr/bin/env ruby

require 'simplecov'

base_dir = ENV.fetch("COVERAGE_BASE_DIR", "./coverage_results")
file_pattern = ENV.fetch("COVERAGE_NAME_PATTERN", ".resultset*.json")

SimpleCov.configure do
  coverage_dir(ENV["COVERAGE_OUTPUT_DIR"])

  # Configure exit behaviour
  minimum_coverage(ENV["COVERAGE_MINIMUM_COVERAGE"])
  minimum_coverage_by_file(ENV["COVERAGE_MINIMUM_COVERAGE_BY_FILE"])
  maximum_coverage_drop(ENV["COVERAGE_MAXIMUM_COVERAGE_DROP"])
  refuse_coverage_drop if ENV["COVERAGE_REFUSE_COVERAGE_DROP"]
end

all_results = Dir["#{base_dir}/#{file_pattern}"]
results = all_results.map { |file| SimpleCov::Result.from_hash(JSON.parse(File.read(file))) }
SimpleCov::ResultMerger.merge_results(*results).tap do |result|
  SimpleCov::ResultMerger.store_result(result)
end
