#!/usr/bin/env ruby

# Bundle Update Bot:
#
# - update the repository owned by the bot defined by ENV['BOT_NAME']
#   default rad-bot
# - push to the @upstream_repository, which may or may not be owned
#   by the bot. Note, if the @upstream_repository is not owned by
#   the bot, the bot should be a member of the repo, or its organization.

require 'octokit'
require 'git'

# mainly for rspec
def set_client(client)
  @client = client
end

def set_working_repo(working_repo)
  @working_repo = working_repo
end

def get_bot_name
  @bot_name
end

def get_upstream_repository_name
  @upstream_repository_name
end

def get_upstream_branch
  @upstream_branch
end

def get_update_branch
  @update_branch
end

def get_bot_working_directory
  @bot_working_directory
end

def get_exit_code
  @exit_code
end

def set_exit_code(exit_code)
  @exit_code = exit_code
end

def required_environment_exists
  initialize_environment

  # This bot will fail if a personal access token for the bot is not
  # set, and its SSH key is not mounted into ~/.ssh along with a suitable
  # .ssh/config which should set StrictHostKeyChecking no
  required_environment = [
    'GIT_REPO_NAME',
    'BOT_TOKEN'
  ]
  required_environment.each do |required_env|
    unless ENV.has_key? required_env
      $stderr.puts "#{required_env} Missing! Please supply the following Environment\n  #{required_environment.join("\n  ")}"
      @exit_code = 1
      return
    end
  end

  unless File.exists? "#{ENV['HOME']}/.ssh"
    $stderr.puts "A config and SSH private key are required in #{ENV['HOME']}/.ssh"
    @exit_code = 1
    return
  end

  unless File.exists?( @bot_working_directory ) &&
          File.readable?( @bot_working_directory ) &&
          File.writable?( @bot_working_directory )
    $stderr.puts "#{@bot_working_directory} directory is required to exist with read and write permission."
    @exit_code = 1
    return
  end

  return true
end

def initialize_environment
  @exit_code = 0
  @branch_exists = {}
  @repo_name = ENV['GIT_REPO_NAME']

  @bot_name = 'rad-bot'
  if ENV['BOT_NAME']
    @bot_name = ENV['BOT_NAME']
  end

  @upstream_repository_name = @bot_name
  if ENV['UPSTREAM_REPOSITORY_NAME']
    @upstream_repository_name = ENV['UPSTREAM_REPOSITORY_NAME']
  end

  @upstream_branch = 'develop'
  if ENV['UPSTREAM_BRANCH']
    @upstream_branch = ENV['UPSTREAM_BRANCH']
  end

  @update_branch = 'bundle_update'
  if ENV['UPDATE_BRANCH']
    @update_branch = ENV['UPDATE_BRANCH']
  end

  @bot_working_directory = '/bots'
  if ENV['BOT_WORKING_DIRECTORY']
    @bot_working_directory = ENV['BOT_WORKING_DIRECTORY']
  end

  @upstream_repository = "#{@upstream_repository_name}/#{@repo_name}"
  @upstream_repository_uri = "git@github.com:#{@upstream_repository}.git"
  @update_repository = "#{@bot_name}/#{@repo_name}"
  @update_repository_uri = "git@github.com:#{@update_repository}.git"
end

def client
  unless @client
    @client = Octokit::Client.new(:access_token => ENV['BOT_TOKEN'])
    @client.login
  end
  @client
end

def branch_exists(name)
  if @branch_exists.has_key? name
    return @branch_exists[name]
  end

  begin
    client.reference(@update_repository, "heads/#{name}")
    @branch_exists[name] = true
  rescue Octokit::NotFound
    @branch_exists[name] = false
  end
end

def working_repo
  if @working_repo
    return @working_repo
  end
  if branch_exists @update_branch
    @working_repo = Git.clone(
        @update_repository_uri,
        @repo_name,
        branch: @update_branch
    )
  else
    @working_repo = Git.clone(
      @update_repository_uri,
      @repo_name
    )
    @working_repo.branch(@update_branch).checkout
  end
  @working_repo
end

def prepare_working_repo
  return if @exit_code > 0
  begin
    Dir.chdir(@bot_working_directory)
    Dir.chdir(working_repo.dir.path)
    working_repo.lib.remote_add 'upstream', @upstream_repository_uri
    working_repo.pull 'upstream', @upstream_branch
  rescue
    $stderr.puts "Problem Preparing Working Repository"
    @exit_code = 1
  end
end

def updates_exist
  prepare_working_repo
  return if @exit_code > 0
  updated = false

  begin
    # remove the Gemfile.lock and re bundle to the local vendor/bundle
    # this will create a new Gemfile.lock with any new gem versions,
    # essentially the same as running bundle update, but bundle
    # update does not let me specify a local install path
    File.unlink 'Gemfile.lock'
    Bundler.clean_system 'bundle install --no-deployment --path vendor/bundle'
    diff = working_repo.diff('Gemfile.lock')
    if diff.size > 0
      updated = true
    end
  rescue
    $stderr.puts "Problem checking for updates"
    @exit_code = 1
    updated = false
  end
  return updated
end

def publish_changes
  return if @exit_code > 0

  begin
    working_repo.config('user.name',@bot_name)
    working_repo.config('user.email',"#{@bot_name}@duke.edu")
    working_repo.add('Gemfile.lock')
    working_repo.commit("#{@bot_name} detected updates to bundled gems")
    working_repo.push('origin',@update_branch)
  rescue
    $stderr.puts "Problem Publishing Changes!"
    @exit_code = 1
  end
end

def notify_changes
  return if @exit_code > 0

  title = "WIP: [#{@bot_name}]: Bundled Gem Updates Detected!"
  body = "
Do not Merge this PR. It is meant to allow CI tests for the
updated gems.
"
  this_pr = nil
  # create a Pull Request if it does not already exist
  begin
    upstream_repo = client.repo(@upstream_repository)
    this_pr = client.create_pull_request(
      upstream_repo.id,
      @upstream_branch,
      "#{@bot_name}:#{@update_branch}",
      title,
      body
    )
    request_pull_request_reviewers(upstream_repo, this_pr)
  rescue Octokit::UnprocessableEntity => e
    unless e.message.include? "pull request already exists"
      $stderr.puts "#{e.message}"
      @exit_code = 1
    end
    return
  rescue Octokit::InvalidRepository => e
    $stderr.puts "#{e.message}"
    @exit_code = 1
    return
  end
end

def request_pull_request_reviewers(repo, pull_request)
  return if @exit_code > 0
  return unless ENV.has_key? 'PR_REVIEWERS'

  begin
    reviewers = ENV['PR_REVIEWERS'].split(',').reject{|c| c == client.login }
    client.request_pull_request_review(repo.id, pull_request.number, reviewers)
  rescue
    $stderr.puts "Problem adding pull request reviewers!"
    @exit_code = 1
  end
  return
end

def run_bot
  return unless required_environment_exists
  if updates_exist
    publish_changes
    notify_changes
  end
end

# MAIN
# http://razorconsulting.com.au/rspec-testing-a-simple-ruby-script.html
if $0 == __FILE__
  run_bot
  exit(@exit_code)
end
