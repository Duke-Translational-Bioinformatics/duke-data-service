shared_context 'mocked openid request to' do |build_openid_authentication_service|
  include_context 'requires let variables', [:first_time_user_access_token,
  :first_time_user_userinfo,
  :existing_user_access_token,
  :existing_user_userinfo,
  :existing_first_authenticating_access_token,
  :existing_first_authenticating_user_userinfo,
  :invalid_access_token]

  let(:openid_authentication_service) { send(build_openid_authentication_service) }

  before do
    WebMock.reset!
    stub_request(:post, "#{openid_authentication_service.base_uri}/userinfo").
      with(:body => "access_token=#{first_time_user_access_token}").
      to_return(:status => 200, :body => first_time_user_userinfo.to_json)

    stub_request(:post, "#{openid_authentication_service.base_uri}/userinfo").
      with(:body => "access_token=#{existing_user_access_token}").
      to_return(:status => 200, :body => existing_user_userinfo.to_json)

    stub_request(:post, "#{openid_authentication_service.base_uri}/userinfo").
      with(:body => "access_token=#{existing_first_authenticating_access_token}").
      to_return(:status => 200, :body => existing_first_authenticating_user_userinfo.to_json)

    stub_request(:post, "#{openid_authentication_service.base_uri}/userinfo").
      with(:body => "access_token=#{invalid_access_token}").
      to_return(:status => 401, :body => {error: "invalid_token", error_description: "Invalid access token: #{invalid_access_token}"}.to_json)
  end
end

shared_examples 'an authentication service' do
  it { is_expected.to respond_to('get_user_for_access_token') }
  it { is_expected.to respond_to('login_initiation_url') }

  describe 'associations' do
    it {
      is_expected.to have_many(:user_authentication_services)
      is_expected.to belong_to(:identity_provider)
    }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :service_id }
    it { is_expected.to validate_presence_of :base_uri }
    it { is_expected.to validate_presence_of :client_id }
    it { is_expected.to validate_presence_of :login_initiation_uri }
    it { is_expected.to validate_presence_of :login_response_type }

    context 'is_default' do
      it 'should allow only one default authentication_service of any type' do
        subject.update(is_default: true) unless subject.is_default?

        [:duke_authentication_service, :openid_authentication_service].each do |service_sym|
            new_default_service = FactoryBot.build(service_sym, :default)
            expect(new_default_service).not_to be_valid
            non_default_service = FactoryBot.build(service_sym)
            expect(non_default_service).to be_valid
        end

        subject.update(is_default: false)

        [:duke_authentication_service, :openid_authentication_service].each do |service_sym|
          new_default_service = FactoryBot.build(service_sym, :default)
          expect(new_default_service).to be_valid
          non_default_service = FactoryBot.build(service_sym)
          expect(non_default_service).to be_valid
        end
      end
    end
  end

  describe 'login_initiation_url' do
    it {
      expect(subject.login_initiation_url).to eq([
        subject.base_uri,
        subject.login_initiation_uri
      ].join('/') + '?' + [
        "response_type=#{subject.login_response_type}",
        "client_id=#{subject.client_id}"
      ].join('&'))
    }
  end

  describe 'get_user_for_access_token' do
    context 'with valid token' do
      context 'for first time user' do
        it 'should return an unpersisted user with an unpersisted user_authentication_service assigned to user.current_user_authenticaiton_service' do
          returned_user = subject.get_user_for_access_token(first_time_user_access_token)
          expect(returned_user).not_to be_persisted
          expect(returned_user.current_user_authenticaiton_service).not_to be_nil
          expect(returned_user.current_user_authenticaiton_service).not_to be_persisted
          expect(returned_user.current_user_authenticaiton_service.authentication_service_id).to eq(subject.id)
        end
      end

      context 'for existing user' do
        context 'already authenticated with this authentication service' do
          it 'should return a persisted user with a persisted user_authentication_service assigned to user.current_user_authenticaiton_service' do
            returned_user = subject.get_user_for_access_token(existing_user_access_token)
            expect(returned_user).to be_persisted
            expect(returned_user.id).to eq(existing_user.id)
            expect(returned_user.current_user_authenticaiton_service).not_to be_nil
            expect(returned_user.current_user_authenticaiton_service).to be_persisted
            expect(returned_user.current_user_authenticaiton_service.id).to eq(existing_user_auth.id)
          end
        end

        context 'not authenticated with this authentication service' do
          it 'should return a persisted user with the an unpersisted user_authentication_service assigned to user.current_user_authenticaiton_service' do
            returned_user = subject.get_user_for_access_token(existing_first_authenticating_access_token)
            expect(returned_user).to be_persisted
            expect(returned_user.id).to eq(existing_first_authenticating_user.id)
            expect(returned_user.current_user_authenticaiton_service).not_to be_nil
            expect(returned_user.current_user_authenticaiton_service).not_to be_persisted
          end
        end
      end
    end

    context 'with invalid token' do
      it {
        expect {
          subject.get_user_for_access_token(invalid_access_token)
        }.to raise_error(InvalidAccessTokenException)
      }
    end

    context 'with nil token' do
      it {
        expect {
          subject.get_user_for_access_token(nil)
        }.to raise_error(InvalidAccessTokenException)
      }
    end
  end
end

shared_examples 'an authentication request endpoint' do
  include_context 'requires let variables', [
    :first_time_user,
    :first_time_user_access_token,
    :existing_user,
    :existing_user_access_token,
    :invalid_access_token]

  it_behaves_like 'a GET request' do
    describe 'for first time users' do
      let(:payload) {
        payload = { access_token: first_time_user_access_token }
        payload[:authentication_service_id] = authentication_service.service_id unless authentication_service.is_default?
        payload
      }

      it 'should create a new User and return an api JWT when provided a valid access_token by a registered AuthenticationService' do
        expect(authentication_service).to be_persisted
        pre_time = DateTime.now.to_i
        expect{
          expect {
            is_expected.to eq(200)
          }.to change{UserAuthenticationService.count}.by(1)
        }.to change{User.count}.by(1)
        post_time = DateTime.now.to_i
        expect(response.status).to eq(200)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        token_wrapper = JSON.parse(response.body)
        expect(token_wrapper).to have_key('api_token')
        decoded_token = JWT.decode(token_wrapper['api_token'],
          Rails.application.secrets.secret_key_base
        )[0]
        expect(decoded_token).to be
        %w(id service_id exp).each do |expected_key|
          expect(decoded_token).to have_key(expected_key)
        end
        expect(decoded_token['service_id']).to eq(authentication_service.service_id)
        created_user = User.find(decoded_token['id'])
        expect(created_user).to be
        expect(created_user.display_name).to eq(first_time_user[:display_name])
        expect(created_user.username).to eq(first_time_user[:username])
        expect(created_user.first_name).to eq(first_time_user[:first_name])
        expect(created_user.last_name).to eq(first_time_user[:last_name])
        expect(created_user.email).to eq(first_time_user[:email])
        expect(created_user.last_login_at.to_i).to be >= pre_time
        expect(created_user.last_login_at.to_i).to be <= post_time
        created_user_authentication_service = created_user.user_authentication_services.where(uid: first_time_user[:username]).first
        expect(created_user_authentication_service).to be
        expect(created_user_authentication_service.authentication_service_id).to eq(authentication_service.id)
      end

      it_behaves_like 'an annotate_audits endpoint' do
        let(:audit_should_include) {{}}

        it 'should set the newly created user as the user' do
          is_expected.to eq(expected_response_status)
          last_audit = Audited.audit_class.where(
            auditable_type: expected_auditable_type.to_s
          ).where(
            'comment @> ?', {action: called_action, endpoint: url}.to_json
          ).order(:created_at).last
          expect(last_audit.user).to be
          expect(last_audit.user.username).to eq(first_time_user[:username])
        end
      end
    end

    describe 'for existing users' do
      let(:payload) {
        {
          access_token: existing_user_access_token,
          authentication_service_id: authentication_service.service_id
        }
      }

      it 'should update user.last_login_at and return an api JWT when provided a JWT access_token encoded with our secret by a registered AuthenticationService' do
        original_last_login_at = existing_user.last_login_at.to_i
        pre_time = DateTime.now.to_i
        is_expected.to eq(200)
        post_time = DateTime.now.to_i
        expect(response.status).to eq(200)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        token_wrapper = JSON.parse(response.body)
        expect(token_wrapper).to have_key('expires_on')
        expect(token_wrapper).to have_key('api_token')
        decoded_token = JWT.decode(token_wrapper['api_token'],
          Rails.application.secrets.secret_key_base
        )[0]
        expect(decoded_token).to be
        %w(id service_id exp).each do |expected_key|
          expect(decoded_token).to have_key(expected_key)
        end
        expect(decoded_token['id']).to eq(existing_user.id)
        expect(decoded_token['service_id']).to eq(authentication_service.service_id)
        existing_user = User.find(decoded_token['id'])
        expect(existing_user).to be
        expect(existing_user.id).to eq(existing_user.id)
        expect(existing_user.last_login_at.to_i).not_to eq(original_last_login_at)
        expect(existing_user.last_login_at.to_i).to be >= pre_time
        expect(existing_user.last_login_at.to_i).to be <= post_time
      end

      context 'nil payload' do
        let(:payload) { nil }
        it 'should respond with an error when not provided an access_token' do
          is_expected.to eq(400)
          expect(response.status).to eq(400)
          expect(response.body).to be
          error_response = JSON.parse(response.body)
          %w(error reason suggestion).each do |expected_key|
            expect(error_response).to have_key expected_key
          end
          expect(error_response).to have_key('code')
          expect(error_response['code']).to eq('not_provided')
          expect(error_response['error']).to eq(400)
          expect(error_response['reason']).to eq('no access_token')
          expect(error_response['suggestion']).to eq('you might need to login through an authentication service')
        end
      end

      context 'nil access_token' do
        let(:payload) {
          {
            access_token: nil,
            authentication_service_id: authentication_service.service_id
          }
        }
        it 'should respond with an error when not provided an access_token' do
          is_expected.to eq(401)
          expect(response.status).to eq(401)
          expect(response.body).to be
          error_response = JSON.parse(response.body)
          %w(error reason suggestion).each do |expected_key|
            expect(error_response).to have_key expected_key
          end
          expect(error_response).to have_key('code')
          expect(error_response['code']).to eq('not_provided')
          expect(error_response['error']).to eq(401)
          expect(error_response['reason']).to eq('invalid access_token')
          expect(error_response['suggestion']).to eq('token not properly signed')
        end
      end

      context 'unknown authentication_service' do
        let(:payload) {
          {
            access_token: existing_user_access_token,
            authentication_service_id: SecureRandom.uuid
          }
        }

        it 'should respond with an error when the authentication_service_id is not registered' do
          original_last_login_at = existing_user.last_login_at.to_i
          is_expected.to eq(401)
          expect(response.status).to eq(401)
          expect(response.body).to be
          error_response = JSON.parse(response.body)
          %w(error reason suggestion).each do |expected_key|
            expect(error_response).to have_key expected_key
          end
          expect(error_response).to have_key('code')
          expect(error_response['code']).to eq('not_provided')
          expect(error_response['error']).to eq(401)
          expect(error_response['reason']).to eq('invalid access_token')
          expect(error_response['suggestion']).to eq('authentication service not registered')
          existing_user.reload
          expect(existing_user.last_login_at.to_i).to eq(original_last_login_at)
        end
      end

      context 'invalid token' do
        let(:payload) {
          {
            access_token: invalid_access_token,
            authentication_service_id: authentication_service.service_id
          }
        }

        it 'should respond with an error' do
          original_last_login_at = existing_user.last_login_at.to_i
          is_expected.to eq(401)
          expect(response.status).to eq(401)
          expect(response.body).to be
          error_response = JSON.parse(response.body)
          %w(error reason suggestion).each do |expected_key|
            expect(error_response).to have_key expected_key
          end
          expect(error_response).to have_key('code')
          expect(error_response['code']).to eq('not_provided')
          expect(error_response['error']).to eq(401)
          expect(error_response['reason']).to eq('invalid access_token')
          expect(error_response['suggestion']).to eq('token not properly signed')
          existing_user.reload
          expect(existing_user.last_login_at.to_i).to eq(original_last_login_at)
        end
      end
    end
  end
end

shared_examples 'an authentication_service:create task' do |
  rake_task_name_sym: :rake_task_name,
  authentication_service_class_sym: :resource_class,
  expected_env_keys_sym: :required_env|

  require 'active_support/testing/stream'
  include ActiveSupport::Testing::Stream

  let(:task_name) { send(rake_task_name_sym) }
  let(:authentication_service_class) { send(authentication_service_class_sym) }
  let(:expected_env_keys) { send(expected_env_keys_sym) }
  let(:invoke_task) { silence_stream(STDOUT) { subject.invoke } }

  it { expect(subject.prerequisites).to  include("environment") }

  context 'ENV[AUTH_SERVICE_IS_DEFAULT] false' do
    before do
      ENV['AUTH_SERVICE_IS_DEFAULT'] = 'false'
    end
    context 'with existing default authentication service' do
      it {
        FactoryBot.create(authentication_service_class.name.underscore.to_sym, :default)
        expected_env_keys.each do |expected_env_key|
          expect(ENV[expected_env_key]).to be_truthy
        end
        expect {
          invoke_task
        }.to change{authentication_service_class.count}.by(1)
        created_authentication_service = authentication_service_class.where(service_id: ENV['AUTH_SERVICE_SERVICE_ID']).take
        expect(created_authentication_service).to be
        expected_env_keys.each do |expected_env_key|
          obj_attribute = expected_env_key.gsub(/AUTH\_SERVICE\_/,'').downcase
          expect(created_authentication_service.send(obj_attribute)).to eq(ENV[expected_env_key])
        end
        expect(created_authentication_service.is_default?).not_to be
      }
    end
    context 'with no existing default authentication service' do
      it {
        expected_env_keys.each do |expected_env_key|
          expect(ENV[expected_env_key]).to be_truthy
        end
        expect {
          invoke_task
        }.to change{authentication_service_class.count}.by(1)
        created_authentication_service = authentication_service_class.where(service_id: ENV['AUTH_SERVICE_SERVICE_ID']).take
        expect(created_authentication_service).to be
        expected_env_keys.each do |expected_env_key|
          obj_attribute = expected_env_key.gsub(/AUTH\_SERVICE\_/,'').downcase
          expect(created_authentication_service.send(obj_attribute)).to eq(ENV[expected_env_key])
        end
        expect(created_authentication_service.is_default?).not_to be
      }
    end
  end

  context 'ENV[AUTH_SERVICE_IS_DEFAULT] true' do
    before do
      ENV['AUTH_SERVICE_IS_DEFAULT'] = 'true'
    end
    context 'with existing default authentication service' do
      it {
        FactoryBot.create(authentication_service_class.name.underscore.to_sym, :default)
        expected_env_keys.each do |expected_env_key|
          expect(ENV[expected_env_key]).to be_truthy
        end
        expect {
          expect {
            invoke_task
          }.to raise_error(StandardError)
        }.not_to change{authentication_service_class.count}
      }
    end
    context 'with no existing default authentication service' do
      it {
        expected_env_keys.each do |expected_env_key|
          expect(ENV[expected_env_key]).to be_truthy
        end
        expect {
          invoke_task
        }.to change{authentication_service_class.count}.by(1)
        created_authentication_service = authentication_service_class.where(service_id: ENV['AUTH_SERVICE_SERVICE_ID']).take
        expect(created_authentication_service).to be
        expected_env_keys.each do |expected_env_key|
          obj_attribute = expected_env_key.gsub(/AUTH\_SERVICE\_/,'').downcase
          expect(created_authentication_service.send(obj_attribute)).to eq(ENV[expected_env_key])
        end
        expect(created_authentication_service.is_default?).to be
      }
    end
  end
end

shared_examples 'an authentication_service:destroy task' do |
  rake_task_name_sym: :rake_task_name,
  authentication_service_class_sym: :resource_class|

  require 'active_support/testing/stream'
  include ActiveSupport::Testing::Stream

  let(:task_name) { send(rake_task_name_sym) }
  let(:authentication_service_class) { send(authentication_service_class_sym) }

  let(:invoke_task) { silence_stream(STDOUT) { subject.invoke } }
  it { expect(subject.prerequisites).to  include("environment") }

  context 'default authentication_service' do
    before do
      FactoryBot.attributes_for(authentication_service_class.name.underscore.to_sym).each do |key,value|
        ENV["AUTH_SERVICE_#{key.upcase}"] = value
      end
      FactoryBot.create(authentication_service_class.name.underscore.to_sym, :from_auth_service_env, :default)
    end

    it {
      expect {
        expect {
          invoke_task
        }.to output("WARNING: destroying default authentication_service\n").to_stderr
      }.to change{authentication_service_class.count}.by(-1)
    }
  end

  context 'non default authentication_service' do
    before do
      FactoryBot.attributes_for(authentication_service_class.name.underscore.to_sym).each do |key,value|
        ENV["AUTH_SERVICE_#{key.upcase}"] = value
      end
      FactoryBot.create(authentication_service_class.name.underscore.to_sym, :from_auth_service_env)
    end

    it {
      expect {
        invoke_task
      }.to change{authentication_service_class.count}.by(-1)
    }
  end
end

shared_examples 'an authentication_service_serializer serializable resource' do
  let(:expected_attributes) {{
    'id' => resource.id,
    'service_id' => resource.service_id,
    'name' => resource.name,
    'login_initiation_url' => resource.login_initiation_url,
    'is_deprecated' => resource.is_deprecated,
    'is_default' => resource.is_default,
    'base_uri' => resource.base_uri,
    'login_response_type' => resource.login_response_type
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end

shared_examples 'an authentication_service_preview_serializer serializable resource' do
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'is_affiliate_search_supported' => !resource.identity_provider.nil?
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
