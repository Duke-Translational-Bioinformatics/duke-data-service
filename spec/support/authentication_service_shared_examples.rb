shared_context 'mocked openid request to' do |build_openid_authentication_service|
  let(:openid_authentication_service) { send(build_openid_authentication_service) }
  # requires the following to be let:
  #   first_time_user_access_token
  #   first_time_user_userinfo
  #   existing_user_access_token
  #   existing_user_userinfo
  #   existing_first_authenticating_access_token
  #   existing_first_authenticating_user_userinfo
  #   invalid_access_token
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

  describe 'associations' do
    it {
      is_expected.to have_many(:user_authentication_services)
    }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :service_id }
    it { is_expected.to validate_presence_of :base_uri }

    context 'is_default' do
      it 'should allow only one default authentication_service of any type' do
        subject.update(is_default: true) unless subject.is_default?

        [:duke_authentication_service, :openid_authentication_service].each do |service_sym|
            new_default_service = FactoryGirl.build(service_sym, :default)
            expect(new_default_service).not_to be_valid
            non_default_service = FactoryGirl.build(service_sym)
            expect(non_default_service).to be_valid
        end

        subject.update(is_default: false)

        [:duke_authentication_service, :openid_authentication_service].each do |service_sym|
          new_default_service = FactoryGirl.build(service_sym, :default)
          expect(new_default_service).to be_valid
          non_default_service = FactoryGirl.build(service_sym)
          expect(non_default_service).to be_valid
        end
      end
    end
  end

  context 'get_user_for_access_token' do
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
  end
end
