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
  user.system_permission.destroy if user.system_permission
  user.affiliations.destroy_all
  Audited.audit_class.where(user_id: user.id, auditable_type: "Upload").each do |ua|
    $stderr.puts "Upload Audit #{ua.id}"
    if Upload.where(id: ua.auditable_id).exists?
      u = Upload.find(ua.auditable_id)
      $stderr.puts "Cleaning #{u.project_id} #{u.id}"
      sp = u.storage_provider
      sp.delete_object(u.project_id, u.id)
      sp.delete_container(u.project_id)
      u.chunks.destroy_all
      u.destroy
    end
    ua.destroy
  end
  Audited.audit_class.where(user_id: user.id, auditable_type: 'Project').each do |up|
    $stderr.puts "Project Audit #{up.id}"
    if Project.where(id: up.auditable_id).exists?
      p = Project.find(up.auditable_id)
      $stderr.puts "Destroying project #{p.id}"
      p.folders.destroy_all
      p.project_permissions.destroy_all
      p.affiliations.destroy_all
      p.destroy
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
    auth_service = get_auth_service
    api_test_user = get_user(auth_service)
    if api_test_user
      clean_artifacts(api_test_user.user)
      api_test_user.user.destroy
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
end
