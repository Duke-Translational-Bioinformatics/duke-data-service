require 'rails_helper'

describe "identity_provider" do
  describe "identity_provider:ldap:create" do
    include_context "rake"
    include_context 'with env_override'
    let(:task_name) { "identity_provider:ldap:create" }
    let(:resource_class) { LdapIdentityProvider }
    let(:identity_provider_attributes) { FactoryBot.attributes_for(:ldap_identity_provider) }

    context 'missing ENV[IDENTITY_PROVIDER_HOST]' do
      let(:env_override) { {
        'IDENTITY_PROVIDER_PORT' => identity_provider_attributes[:port],
        'IDENTITY_PROVIDER_LDAP_BASE' => identity_provider_attributes[:ldap_base]
      } }

      it {
        expect { invoke_task }.to raise_error(/ENV\[IDENTITY_PROVIDER_HOST\], ENV\[IDENTITY_PROVIDER_PORT\], and ENV\[IDENTITY_PROVIDER_LDAP_BASE\] are required/)
      }
    end

    context 'missing ENV[IDENTITY_PROVIDER_PORT]' do
      let(:env_override) { {
        'IDENTITY_PROVIDER_HOST' => identity_provider_attributes[:host],
        'IDENTITY_PROVIDER_LDAP_BASE' => identity_provider_attributes[:ldap_base]
      } }
      it {
        expect { invoke_task }.to raise_error(/ENV\[IDENTITY_PROVIDER_HOST\], ENV\[IDENTITY_PROVIDER_PORT\], and ENV\[IDENTITY_PROVIDER_LDAP_BASE\] are required/)
      }
    end

    context 'missing ENV[IDENTITY_PROVIDER_LDAP_BASE]' do
      let(:env_override) { {
        'IDENTITY_PROVIDER_HOST' => identity_provider_attributes[:host],
        'IDENTITY_PROVIDER_PORT' => identity_provider_attributes[:port]
      } }
      it {
        expect { invoke_task }.to raise_error(/ENV\[IDENTITY_PROVIDER_HOST\], ENV\[IDENTITY_PROVIDER_PORT\], and ENV\[IDENTITY_PROVIDER_LDAP_BASE\] are required/)
      }
    end

    context 'required ENV present' do
      let(:env_override) { {
        'IDENTITY_PROVIDER_HOST' => identity_provider_attributes[:host],
        'IDENTITY_PROVIDER_PORT' => identity_provider_attributes[:port],
        'IDENTITY_PROVIDER_LDAP_BASE' => identity_provider_attributes[:ldap_base]
      } }

      it {
        expect {
          invoke_task
        }.to change{LdapIdentityProvider.count}.by(1)
        expect(LdapIdentityProvider.where(
          host: ENV['IDENTITY_PROVIDER_HOST'],
          port: ENV['IDENTITY_PROVIDER_PORT'],
          ldap_base: ENV['IDENTITY_PROVIDER_LDAP_BASE']
        )).to exist
      }
    end
  end

  describe 'identity_provider:destroy' do
    include_context "rake"
    include_context 'with env_override'
    let(:task_name) { "identity_provider:destroy" }
    let(:identity_provider) { FactoryBot.create(:ldap_identity_provider) }

    it { expect(subject.prerequisites).to  include("environment") }

    context 'missing ENV[IDENTITY_PROVIDER_ID]' do
      it { expect(ENV['IDENTITY_PROVIDER_ID']).to be_nil }
      it { expect { invoke_task }.to raise_error(/ENV\[IDENTITY_PROVIDER_ID\] is required/) }
    end

    context 'unknown IDENTITY_PROVIDER_ID' do
      let(:env_override) { {
        'IDENTITY_PROVIDER_ID' => "#{SecureRandom.random_number}"
      } }
      it { expect { invoke_task }.not_to raise_error }
    end

    context 'IDENTITY_PROVIDER_ID exists' do
      let(:env_override) { {
        'IDENTITY_PROVIDER_ID' => "#{identity_provider.id}"
      } }

      context 'specified identity_provider registered to an authentication_service' do
        let(:authentication_service) { FactoryBot.create(:openid_authentication_service, identity_provider: identity_provider) }
        before(:example) { expect(authentication_service).to be_persisted }
        it { expect { invoke_task }.to raise_error(/identity_provider is registered to one or more authentication_services. use auth_service:identity_provider:remove/) }
      end

      context 'identity_provider not registered to an authentication_service' do
        it { expect { invoke_task }.to change{IdentityProvider.count}.by(-1) }
      end
    end
  end
end
