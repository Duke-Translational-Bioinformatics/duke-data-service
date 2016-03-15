require 'factory_girl_rails'
require 'faker'

def user_name
  'DDS_api_test_user'
end

def get_auth_service
  auth_service = AuthenticationService.first
  raise 'No AuthenticationService found, run rake authentication_service:create first' unless auth_service
  auth_service
end

def get_user(auth_service)
  auth_service.user_authentication_services.where(
    uid: user_name
  ).first
end

def clean_artifacts(user)
  Container.auditing_enabled = false
  Project.auditing_enabled = false
  ApiKey.auditing_enabled = false
  Affiliation.auditing_enabled = false
  Chunk.auditing_enabled = false
  ProjectPermission.auditing_enabled = false
  SoftwareAgent.auditing_enabled = false
  Upload.auditing_enabled = false
  Audited.audit_class.as_user(user) do
    user.system_permission.destroy if user.system_permission
    user.api_key.destroy if user.api_key
    SoftwareAgent.where(creator_id: user.id).all.each do |sa|
      sa.api_key.destroy
      sa.destroy
    end
    user.affiliations.destroy_all
  end

  Audited.audit_class.where(user_id: user.id, auditable_type: "Upload").each do |ua|
    if Upload.where(id: ua.auditable_id).exists?
      u = Upload.find(ua.auditable_id)
      $stderr.puts "Cleaning #{u.project_id} #{u.id}"
      sp = u.storage_provider
      begin
        sp.delete_object(u.project_id, u.id)
        sp.delete_container(u.project_id)
      rescue StorageProviderException => e
        $stderr.puts "error deleting storage_provider artifacts #{e.message}"
      end
      Audited.audit_class.as_user(user) do
        u.chunks.destroy_all
        u.destroy
      end
    end
    ua.destroy
  end
  Audited.audit_class.where(user_id: user.id, auditable_type: 'Project').each do |up|
    $stderr.puts "Project Audit #{up.id}"
    if Project.where(id: up.auditable_id).exists?
      p = Project.find(up.auditable_id)
      $stderr.puts "Destroying project #{p.id}"
      Audited.audit_class.as_user(user) do
        p.folders.all.each do |pf|
          pf.destroy
        end
        p.project_permissions.destroy_all
        p.affiliations.destroy_all
        p.destroy
      end
    end
    up.destroy
  end
  Audited.audit_class.where(user_id: user.id).each do |ra|
    $stderr.puts "Residual Audit #{ra.to_json}"
    if ra.auditable_type.constantize.where(id: ra.auditable_id).exists?
      ra.auditable_type.constantize.find(ra.auditable_id).destroy
    end
    ra.destroy
  end
  #try and get the User creation audits, which do not have user associated with them
  $stderr.puts "looking for residual user audits that do not have userid"
  Audited.audit_class.where(auditable_type: "User").where('audited_changes like ?', "%DDS_api_test_user%").destroy_all
end

namespace :api_test_user do
  desc "creates a 'DDS_api_test_user' if it does not already exist, and prints an API TOKEN with a long TTL"
  task create: :environment do
    auth_service = get_auth_service
    authorized_user = get_user(auth_service)
    unless authorized_user
      test_user = User.create(
        id: SecureRandom.uuid,
        username: user_name,
        etag: SecureRandom.hex,
        email: "#{user_name}@duke.edu",
        display_name: 'DDS API Test User',
        first_name: 'DDS API',
        last_login_at: DateTime.now,
        last_name: 'Test'
      )
      authorized_user = auth_service.user_authentication_services.create(
        uid: 'DDS_api_test_user',
        user: test_user
      )
    end
    token = JWT.encode({
          'id' => authorized_user.user.id,
          'authentication_service_id' => auth_service.id,
          'exp' => Time.now.to_i + 5.years.to_i
        }, Rails.application.secrets.secret_key_base)

    $stdout.print token
  end

  desc "destroys the 'DDS_api_test_user' and all of its artifacts"
  task destroy: :environment do
    User.auditing_enabled = false
    auth_service = get_auth_service
    api_test_user = get_user(auth_service)
    if api_test_user
      clean_artifacts(api_test_user.user)
      api_test_user.user.destroy
      api_test_user.user.audits.destroy_all
      api_test_user.destroy
    else
      $stderr.puts 'DDS_api_test_user not found'
    end
  end

  desc "destroys all of the 'DDS_api_test_user' artifacts"
  task clean: :environment do
    auth_service = get_auth_service
    api_test_user = get_user(auth_service)
    if api_test_user
      clean_artifacts(api_test_user.user)
    else
      $stderr.puts 'DDS_api_test_user not found'
    end
  end

  desc "create or get the api_key for the test user"
  task api_key: :environment do
    auth_service = get_auth_service
    api_test_user = get_user(auth_service)
    if api_test_user
      unless api_test_user.user.api_key
        Audited.audit_class.as_user(api_test_user.user) do
          api_test_user.user.create_api_key(key: SecureRandom.hex)
        end
      end
      $stdout.print api_test_user.user.api_key.key
    else
      $stderr.puts 'DDS_api_test_user not found'
    end
  end

  desc "create or get a software_agent and api_key"
  task software_agent_api_key: :environment do
    auth_service = get_auth_service
    api_test_user = get_user(auth_service)
    if api_test_user
      software_agent = SoftwareAgent.where(creator_id: api_test_user.id).take
      unless software_agent
        Audited.audit_class.as_user(api_test_user.user) do
          software_agent = FactoryGirl.create(:software_agent, :with_key, creator: api_test_user.user)
        end
      end
      $stdout.print software_agent.api_key.key
    else
      $stderr.puts 'DDS_api_test_user not found'
    end
  end
end

namespace :api_test_user_pool do
  desc "creates a pool of users for api tests to use in tests where other users are needed"
  task create: :environment do
    auth_service = get_auth_service
    users = FactoryGirl.build_list(:user_authentication_service, 2, :populated, authentication_service_id: auth_service.id)
    users.each do |auser|
      auser.uid = "api_test_pool_#{auser.uid}"
      auser.save
    end
  end

  desc "destroys the dredd_test_user_pool users and all of their artifacts"
  task destroy: :environment do
    auth_service = get_auth_service
    auth_service.user_authentication_services.where('uid like ?', 'api_test_pool%').each do |puser|
      clean_artifacts(puser.user)
      puser.user.destroy
      puser.destroy
    end
  end
end
