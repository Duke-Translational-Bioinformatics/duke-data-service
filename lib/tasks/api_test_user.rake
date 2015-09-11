namespace :api_test_user do
  desc "creates a 'DDS_api_test_user' if it does not already exist, and prints an API TOKEN with a long TTL"
  task create: :environment do
    user_name = 'DDS_api_test_user'
    auth_service = AuthenticationService.first
    raise 'No AuthenticationService found, run rake authentication_service:create first' unless auth_service
    authorized_user = auth_service.user_authentication_services.where(
      uid: user_name
    ).first
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

    $stdout.puts token
  end

  desc "destroys the 'DDS_api_test_user'"
  task destroy: :environment do
    user_name = 'DDS_api_test_user'
    auth_service = AuthenticationService.first
    raise 'No AuthenticationService found, run rake authentication_service:create first' unless auth_service
    api_test_user = auth_service.user_authentication_services.where(uid: user_name).first
    if api_test_user
      api_test_user.user.destroy
      api_test_user.destroy
    end
  end
end
