require 'rails_helper'

describe "auth_service" do
  include_context 'with env_override'

  describe "auth_service:duke:create" do
    include_context "rake"
    let(:rake_task_name) { "auth_service:duke:create" }
    let(:resource_class) { DukeAuthenticationService }
    let(:required_env) { %w(
        AUTH_SERVICE_SERVICE_ID
        AUTH_SERVICE_BASE_URI
        AUTH_SERVICE_NAME
        AUTH_SERVICE_LOGIN_INITIATION_URI
        AUTH_SERVICE_LOGIN_RESPONSE_TYPE
        AUTH_SERVICE_CLIENT_ID
      )
    }
    let(:authentication_service_attributes) { FactoryBot.attributes_for(:duke_authentication_service) }
    let(:env_override) { {
      "AUTH_SERVICE_SERVICE_ID" => authentication_service_attributes[:service_id],
      "AUTH_SERVICE_BASE_URI" => authentication_service_attributes[:base_uri],
      "AUTH_SERVICE_NAME" => authentication_service_attributes[:name],
      "AUTH_SERVICE_LOGIN_INITIATION_URI" => authentication_service_attributes[:login_initiation_uri],
      "AUTH_SERVICE_LOGIN_RESPONSE_TYPE" => authentication_service_attributes[:login_response_type],
      "AUTH_SERVICE_CLIENT_ID" => authentication_service_attributes[:client_id]
    } }

    it_behaves_like 'an authentication_service:create task'
  end

  describe "auth_service:openid:create" do
    include_context "rake"
    let(:rake_task_name) { "auth_service:openid:create" }
    let(:resource_class) { OpenidAuthenticationService }
    let(:required_env) { %w(
        AUTH_SERVICE_SERVICE_ID
        AUTH_SERVICE_BASE_URI
        AUTH_SERVICE_NAME
        AUTH_SERVICE_LOGIN_INITIATION_URI
        AUTH_SERVICE_LOGIN_RESPONSE_TYPE
        AUTH_SERVICE_CLIENT_ID
      )
    }
    let(:authentication_service_attributes) { FactoryBot.attributes_for(:openid_authentication_service) }
    let(:env_override) { {
      "AUTH_SERVICE_SERVICE_ID" => authentication_service_attributes[:service_id],
      "AUTH_SERVICE_BASE_URI" => authentication_service_attributes[:base_uri],
      "AUTH_SERVICE_NAME" => authentication_service_attributes[:name],
      "AUTH_SERVICE_LOGIN_INITIATION_URI" => authentication_service_attributes[:login_initiation_uri],
      "AUTH_SERVICE_LOGIN_RESPONSE_TYPE" => authentication_service_attributes[:login_response_type],
      "AUTH_SERVICE_CLIENT_ID" => authentication_service_attributes[:client_id],
      "AUTH_SERVICE_CLIENT_SECRET" => authentication_service_attributes[:client_secret]
    } }

    it_behaves_like 'an authentication_service:create task'
  end

  describe 'auth_service:destroy' do
    include_context "rake"
    let(:rake_task_name) { "auth_service:destroy" }

    context 'OpenidAuthenticationService' do
      let(:resource_class) { OpenidAuthenticationService }
      let(:authentication_service_attributes) { FactoryBot.attributes_for(:openid_authentication_service) }
      let(:env_override) { {
        "AUTH_SERVICE_SERVICE_ID" => authentication_service_attributes[:service_id],
        "AUTH_SERVICE_BASE_URI" => authentication_service_attributes[:base_uri],
        "AUTH_SERVICE_NAME" => authentication_service_attributes[:name],
        "AUTH_SERVICE_CLIENT_ID" => authentication_service_attributes[:client_id],
        "AUTH_SERVICE_CLIENT_SECRET" => authentication_service_attributes[:client_secret]
      } }
      it_behaves_like 'an authentication_service:destroy task'
    end

    context 'DukeAuthenticationService' do
      let(:resource_class) { DukeAuthenticationService }
      let(:authentication_service_attributes) { FactoryBot.attributes_for(:duke_authentication_service) }
      let(:env_override) { {
        "AUTH_SERVICE_SERVICE_ID" => authentication_service_attributes[:service_id],
        "AUTH_SERVICE_BASE_URI" => authentication_service_attributes[:base_uri],
        "AUTH_SERVICE_NAME" => authentication_service_attributes[:name]
      } }
      it_behaves_like 'an authentication_service:destroy task'
    end
  end

  describe 'auth_service:transfer_default' do
    include_context "rake"
    let(:task_name) { "auth_service:transfer_default" }
    let(:default_authentication_service) { FactoryBot.create(:duke_authentication_service, :default) }
    let(:non_default_authentication_service) { FactoryBot.create(:openid_authentication_service) }

    context 'missing ENV[FROM_AUTH_SERVICE_ID]' do
      let(:env_override) { {
        'TO_AUTH_SERVICE_ID' => non_default_authentication_service.service_id
      } }

      it { expect { invoke_task }.to raise_error(/please set ENV\[FROM_AUTH_SERVICE_ID\] and ENV\[TO_AUTH_SERVICE_ID\]/) }
    end

    context 'missing ENV[TO_AUTH_SERVICE_ID]' do
      let(:env_override) { {
        'FROM_AUTH_SERVICE_ID' => default_authentication_service.service_id
      } }

      it { expect { invoke_task }.to raise_error(/please set ENV\[FROM_AUTH_SERVICE_ID\] and ENV\[TO_AUTH_SERVICE_ID\]/) }
    end

    context 'from auth_service not found' do
      let(:env_override) { {
        'FROM_AUTH_SERVICE_ID' => SecureRandom.uuid,
        'TO_AUTH_SERVICE_ID' => non_default_authentication_service.service_id
      } }

      it { expect { invoke_task }.to raise_error(/Couldn't find AuthenticationService/) }
    end

    context 'from auth_service is not default' do
      let(:env_override) { {
        'FROM_AUTH_SERVICE_ID' => non_default_authentication_service.service_id,
        'TO_AUTH_SERVICE_ID' => default_authentication_service.service_id
      } }

      it { expect { invoke_task }.to raise_error(/#{non_default_authentication_service.service_id} is not default/) }
    end

    context 'to auth_service not found' do
      let(:env_override) { {
        'FROM_AUTH_SERVICE_ID' => default_authentication_service.service_id,
        'TO_AUTH_SERVICE_ID' => SecureRandom.uuid
      } }

      it { expect { invoke_task }.to raise_error(/Couldn't find AuthenticationService/) }
    end

    context 'success' do
      let(:env_override) { {
        'FROM_AUTH_SERVICE_ID' => default_authentication_service.service_id,
        'TO_AUTH_SERVICE_ID' => non_default_authentication_service.service_id
      } }

      it {
        invoke_task
        default_authentication_service.reload
        non_default_authentication_service.reload
        expect(default_authentication_service.is_default).not_to be
        expect(non_default_authentication_service.is_default).to be
      }
    end
  end

  describe 'auth_service:set_default' do
    include_context "rake"
    let(:task_name) { "auth_service:set_default" }

    context 'missing ENV[AUTH_SERVICE_SERVICE_ID]' do
      it { expect(ENV['AUTH_SERVICE_SERVICE_ID']).to be_nil }
      it { expect { invoke_task }.to raise_error(/AUTH_SERVICE_SERVICE_ID environment variable is required/) }
    end

    context 'specified service does not exist' do
      let(:env_override) { {
        'AUTH_SERVICE_SERVICE_ID' => SecureRandom.uuid
      } }
      it { expect { invoke_task }.to raise_error(/AUTH_SERVICE_SERVICE_ID is not a registered service/) }
    end

    context 'specified service is already default' do
      let(:authentication_service) { FactoryBot.create(:duke_authentication_service, :default) }
      let(:env_override) { {
        'AUTH_SERVICE_SERVICE_ID' => authentication_service.service_id
      } }

      it {
        expect {
          invoke_task expected_stderr: /AUTH_SERVICE_SERVICE_ID service is already default/
        }.not_to raise_error
      }
    end

    context 'specified service is not already default' do
      let(:authentication_service) { FactoryBot.create(:openid_authentication_service) }

      let(:env_override) { {
        'AUTH_SERVICE_SERVICE_ID' => authentication_service.service_id
      } }

      context 'another default service already exists' do
        let(:default_authentication_service) { FactoryBot.create(:duke_authentication_service, :default) }
        it { expect { invoke_task }.to raise_error(Regexp.new("Service #{default_authentication_service.service_id} is already default. Use auth_service_transfer_default instead")) }
      end

      context 'no default service exists' do
        it {
          expect {
            invoke_task
          }.not_to raise_error
        }
      end
    end
  end

  describe 'auth_service:deprecate' do
    include_context "rake"
    let(:task_name) { "auth_service:deprecate" }

    context 'missing ENV[AUTH_SERVICE_SERVICE_ID]' do
      it {
        expect { invoke_task }.to raise_error(/AUTH_SERVICE_SERVICE_ID environment variable is required/)
      }
    end

    context 'specified service does not exist' do
      let(:env_override) { {
        'AUTH_SERVICE_SERVICE_ID' => SecureRandom.uuid
      } }
      it { expect { invoke_task }.to raise_error(/AUTH_SERVICE_SERVICE_ID is not a registered service/) }
    end

    context 'specified service is already deprecated' do
      let(:authentication_service) { FactoryBot.create(:duke_authentication_service, :deprecated) }
      let(:env_override) { {
        'AUTH_SERVICE_SERVICE_ID' => authentication_service.service_id
      } }

      it {
        expect {
          invoke_task expected_stderr: /AUTH_SERVICE_SERVICE_ID service is already deprecated/
        }.not_to raise_error
      }
    end

    context 'specified service is not already deprecated' do
      let(:authentication_service) { FactoryBot.create(:openid_authentication_service) }

      let(:env_override) { {
        'AUTH_SERVICE_SERVICE_ID' => authentication_service.service_id
      } }

      it {
        expect {
          invoke_task
        }.not_to raise_error
        authentication_service.reload
        expect(authentication_service).to be_is_deprecated
      }
    end
  end

  describe 'auth_service:identity_provider:register' do
    include_context "rake"
    let(:task_name) { "auth_service:identity_provider:register" }

    context 'missing ENV[AUTH_SERVICE_ID]' do
      it {
        expect { invoke_task }.to raise_error(/ENV\[AUTH_SERVICE_ID\] and ENV\[IDENTITY_PROVIDER_ID\] are required/)
      }
    end

    context 'missing ENV[IDENTITY_PROVIDER_ID]' do
      it {
        expect { invoke_task }.to raise_error(/ENV\[AUTH_SERVICE_ID\] and ENV\[IDENTITY_PROVIDER_ID\] are required/)
      }
    end

    context 'unknown AUTH_SERVICE_ID' do
      let(:identity_provider) { FactoryBot.create(:ldap_identity_provider) }
      let(:env_override) { {
        'AUTH_SERVICE_ID' => SecureRandom.uuid,
        'IDENTITY_PROVIDER_ID' => "#{identity_provider.id}"
      } }

      it {
        expect { invoke_task }.to raise_error(/authentication_service does not exist/)
      }
    end

    context 'unknown IDENTITY_PROVIDER_ID' do
      let(:authentication_service) { FactoryBot.create(:openid_authentication_service) }
      let(:env_override) { {
        'AUTH_SERVICE_ID' => authentication_service.id,
        'IDENTITY_PROVIDER_ID' => "#{SecureRandom.random_number}"
      } }

      it {
        expect { invoke_task }.to raise_error(/identity_provider does not exist/)
      }
    end

    context 'identity_provider already set' do
      let(:authentication_service) { FactoryBot.create(:openid_authentication_service, :with_ldap_identity_provider) }
      let(:identity_provider) { authentication_service.identity_provider }

      context 'to requested identity_provider' do
        let(:env_override) { {
          'AUTH_SERVICE_ID' => authentication_service.id,
          'IDENTITY_PROVIDER_ID' => "#{identity_provider.id}"
        } }

        it {
          expect {
            invoke_task expected_stderr: /AUTH_SERVICE_ID already registered with IDENTITY_PROVIDER_ID/
          }.not_to raise_error
        }
      end

      context 'to a different identity_provider than the requested identity_provider' do
        let(:other_identity_provider) { FactoryBot.create(:ldap_identity_provider) }
        let(:env_override) { {
          'AUTH_SERVICE_ID' => authentication_service.id,
          'IDENTITY_PROVIDER_ID' => "#{other_identity_provider.id}"
        } }

        it {
          expect { invoke_task }.to raise_error(/AUTH_SERVICE_ID service is registered to a different identity_provider, use auth_service:identity_provider:remove/)
        }
      end
    end

    context 'identity_provder not set' do
      let(:authentication_service) { FactoryBot.create(:openid_authentication_service) }
      let(:identity_provider) { FactoryBot.create(:ldap_identity_provider) }
      let(:env_override) { {
        'AUTH_SERVICE_ID' => authentication_service.id,
        'IDENTITY_PROVIDER_ID' => "#{identity_provider.id}"
      } }

      it {
        expect(authentication_service.identity_provider).to be_nil
        expect {
          invoke_task
        }.not_to raise_error
        authentication_service.reload
        expect(authentication_service.identity_provider).not_to be_nil
        expect(authentication_service.identity_provider.id).to eq(identity_provider.id)
      }
    end
  end

  describe 'auth_service:identity_provider:remove' do
    include_context "rake"
    let(:task_name) { "auth_service:identity_provider:remove" }

    context 'missing ENV[AUTH_SERVICE_ID]' do
      it {
        expect { invoke_task }.to raise_error(/ENV\[AUTH_SERVICE_ID\] is required/)
      }
    end

    context 'unknown AUTH_SERVICE_ID' do
      let(:env_override) { {
        'AUTH_SERVICE_ID' => SecureRandom.uuid
      } }

      it {
        expect { invoke_task }.to raise_error(/authentication_service does not exist/)
      }
    end

    context 'auth_service does not have an identity_provider' do
      let(:authentication_service) { FactoryBot.create(:openid_authentication_service) }
      let(:env_override) { {
        'AUTH_SERVICE_ID' => authentication_service.id
      } }
      it {
        expect {
          invoke_task
        }.not_to raise_error
        authentication_service.reload
        expect(authentication_service.identity_provider).to be_nil
      }
    end

    context 'auth_service has an identity_provider' do
      let(:authentication_service) { FactoryBot.create(:openid_authentication_service, :with_ldap_identity_provider) }
      let(:env_override) { {
        'AUTH_SERVICE_ID' => authentication_service.id
      } }
      it {
        expect(authentication_service.identity_provider).not_to be_nil
        original_identity_provider = authentication_service.identity_provider
        expect {
          invoke_task
        }.not_to raise_error
        authentication_service.reload
        expect(authentication_service.identity_provider).to be_nil
        original_identity_provider.reload
        expect(original_identity_provider).to be_persisted
      }
    end
  end
end
