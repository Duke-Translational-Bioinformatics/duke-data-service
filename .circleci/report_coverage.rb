#!/usr/bin/env ruby

require 'simplecov'

base_dir = ENV.fetch("COVERAGE_BASE_DIR", "./coverage_results")
file_pattern = ENV.fetch("COVERAGE_NAME_PATTERN", ".resultset*.json")
coverage_dir = ENV["COVERAGE_OUTPUT_DIR"]

all_results = Dir["#{base_dir}/#{file_pattern}"]
SimpleCov.coverage_dir(coverage_dir) if coverage_dir
results = all_results.map { |file| SimpleCov::Result.from_hash(JSON.parse(File.read(file))) }
SimpleCov::ResultMerger.merge_results(*results).tap do |result|
  SimpleCov::ResultMerger.store_result(result)
end
