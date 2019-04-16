require 'rails_helper'

describe "auth_service" do
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

    before do
      FactoryBot.attributes_for(:duke_authentication_service).each do |key,value|
        ENV["AUTH_SERVICE_#{key.upcase}"] = value
      end
    end
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

    before do
      FactoryBot.attributes_for(:openid_authentication_service).each do |key,value|
        ENV["AUTH_SERVICE_#{key.upcase}"] = value
      end
    end
    it_behaves_like 'an authentication_service:create task'
  end

  describe 'auth_service:destroy' do
    include_context "rake"
    let(:rake_task_name) { "auth_service:destroy" }

    context 'OpenidAuthenticationService' do
      let(:resource_class) { OpenidAuthenticationService }
      it_behaves_like 'an authentication_service:destroy task'
    end

    context 'DukeAuthenticationService' do
      let(:resource_class) { DukeAuthenticationService }
      it_behaves_like 'an authentication_service:destroy task'
    end
  end

  describe 'auth_service:transfer_default' do
    include_context "rake"
    let(:task_name) { "auth_service:transfer_default" }
    let(:default_authentication_service) { FactoryBot.create(:duke_authentication_service, :default) }
    let(:non_default_authentication_service) { FactoryBot.create(:openid_authentication_service) }

    context 'missing ENV[FROM_AUTH_SERVICE_ID]' do
      before do
        ENV['TO_AUTH_SERVICE_ID'] = non_default_authentication_service.service_id
      end

      it {
        expect {
          invoke_task
        }.to raise_error(StandardError)
      }
    end

    context 'missing ENV[TO_AUTH_SERVICE_ID]' do
      before do
        ENV['FROM_AUTH_SERVICE_ID'] = default_authentication_service.service_id
      end

      it {
        expect {
          invoke_task
        }.to raise_error(StandardError)
      }
    end

    context 'from auth_service not found' do
      before do
        ENV['FROM_AUTH_SERVICE_ID'] = SecureRandom.uuid
        ENV['TO_AUTH_SERVICE_ID'] = non_default_authentication_service.service_id
      end

      it {
        expect {
          invoke_task
        }.to raise_error(StandardError)
      }
    end

    context 'from auth_service is not default' do
      before do
        ENV['FROM_AUTH_SERVICE_ID'] = non_default_authentication_service.service_id
        ENV['TO_AUTH_SERVICE_ID'] = default_authentication_service.service_id
      end

      it {
        expect {
          invoke_task
        }.to raise_error(StandardError)
      }
    end

    context 'to auth_service not found' do
      before do
        ENV['FROM_AUTH_SERVICE_ID'] = default_authentication_service.service_id
        ENV['TO_AUTH_SERVICE_ID'] = SecureRandom.uuid
      end

      it {
        expect {
          invoke_task
        }.to raise_error(StandardError)
      }
    end

    context 'success' do
      before do
        ENV['FROM_AUTH_SERVICE_ID'] = default_authentication_service.service_id
        ENV['TO_AUTH_SERVICE_ID'] = non_default_authentication_service.service_id
      end

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
      it {
        expect { invoke_task }.to raise_error(/AUTH_SERVICE_SERVICE_ID environment variable is required/)
      }
    end

    context 'specified service does not exist' do
      before do
        ENV['AUTH_SERVICE_SERVICE_ID'] = SecureRandom.uuid
      end
      it {
        expect {
          invoke_task expected_stderr: /AUTH_SERVICE_SERVICE_ID is not a registered service/
        }.to raise_error(StandardError)
      }
    end

    context 'specified service is already default' do
      let(:authentication_service) { FactoryBot.create(:duke_authentication_service, :default) }
      before do
        ENV['AUTH_SERVICE_SERVICE_ID'] = authentication_service.service_id
      end

      it {
        expect {
          invoke_task expected_stderr: /AUTH_SERVICE_SERVICE_ID service is already default/
        }.not_to raise_error
      }
    end

    context 'specified service is not already default' do
      let(:authentication_service) { FactoryBot.create(:openid_authentication_service) }

      before do
        ENV['AUTH_SERVICE_SERVICE_ID'] = authentication_service.service_id
      end

      context 'another default service already exists' do
        let(:default_authentication_service) { FactoryBot.create(:duke_authentication_service, :default) }
        it {
          expect {
            invoke_task expected_stderr: Regexp.new("Service #{default_authentication_service.service_id} is already default. Use auth_service_transfer_default instead")
          }.to raise_error(StandardError)
        }
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
      before do
        ENV['AUTH_SERVICE_SERVICE_ID'] = SecureRandom.uuid
      end
      it {
        expect {
          invoke_task expected_stderr: /AUTH_SERVICE_SERVICE_ID is not a registered service/
        }.to raise_error(StandardError)
      }
    end

    context 'specified service is already deprecated' do
      let(:authentication_service) { FactoryBot.create(:duke_authentication_service, :deprecated) }
      before do
        ENV['AUTH_SERVICE_SERVICE_ID'] = authentication_service.service_id
      end

      it {
        expect {
          invoke_task expected_stderr: /AUTH_SERVICE_SERVICE_ID service is already deprecated/
        }.not_to raise_error
      }
    end

    context 'specified service is not already deprecated' do
      let(:authentication_service) { FactoryBot.create(:openid_authentication_service) }

      before do
        ENV['AUTH_SERVICE_SERVICE_ID'] = authentication_service.service_id
      end

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
    include_context 'with env_override'
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
      before do
        ENV['AUTH_SERVICE_ID'] = SecureRandom.uuid
      end

      it {
        expect { invoke_task }.to raise_error(/authentication_service does not exist/)
      }
    end

    context 'auth_service does not have an identity_provider' do
      let(:authentication_service) { FactoryBot.create(:openid_authentication_service) }
      before do
        ENV['AUTH_SERVICE_ID'] = authentication_service.id
      end
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
      before do
        ENV['AUTH_SERVICE_ID'] = authentication_service.id
      end
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
