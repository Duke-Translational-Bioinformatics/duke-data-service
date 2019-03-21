#!/usr/bin/env ruby
require 'octokit'

required_environment = [
  'BOT_NAME',
  'BOT_TOKEN',
  'REPOSITORY',
  'MERGE_TO',
  'MERGE_FROM'
]

required_environment.each do |required_env|
  unless ENV.has_key? required_env
    $stderr.puts "#{required_env} Missing! Please supply the following Environment\n  #{required_environment.join("\n  ")}"
    exit(1)
  end
end
name = ENV['BOT_NAME']
client = Octokit::Client.new(:access_token => ENV['BOT_TOKEN'])
user = client.user
user.login
repo = client.repo("#{ENV['REPOSITORY']}")
diff = client.compare(repo.id, ENV['MERGE_TO'], ENV['MERGE_FROM'])
if diff.status == "ahead" || diff.status == "diverged"
  $stderr.puts "Previous commit detected"
  title = "[#{name}]: Merge Commit Merge"
  body = "
  Please merge commits from a previous Pull Request merge.
  "
  this_pr = nil
  begin
    this_pr = client.create_pull_request(
      repo.id,
      ENV['MERGE_TO'],
      ENV['MERGE_FROM'],
      title,
      body
    )
  rescue Octokit::UnprocessableEntity => e
    raise e unless e.message.include? "pull request already exists"
    $stderr.puts "PR already exists!"
    exit
  end
  reviewers = diff.commits.map{ |c| c.author.login }.reject{|c| c == client.user.login }.uniq
  client.request_pull_request_review(repo.id, this_pr.number, reviewers)
end
exit
