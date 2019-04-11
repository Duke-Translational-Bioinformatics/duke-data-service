require 'rails_helper'

describe "identity_provider" do
  describe "identity_provider:ldap:create" do
    include_context "rake"
    let(:task_name) { "identity_provider:ldap:create" }
    let(:resource_class) { LdapIdentityProvider }
    let(:required_env) { %w(
        IDENTITY_PROVIDER_HOST
        IDENTITY_PROVIDER_PORT
        IDENTITY_PROVIDER_LDAP_BASE
      )
    }
    let(:identity_provider_attributes) { FactoryBot.attributes_for(:ldap_identity_provider) }

    context 'missing ENV[IDENTITY_PROVIDER_HOST]' do
      before do
        ENV['IDENTITY_PROVIDER_PORT'] = identity_provider_attributes[:port]
        ENV['IDENTITY_PROVIDER_LDAP_BASE'] = identity_provider_attributes[:ldap_base]
      end

      it {
        expect {
          invoke_task epected_stderr: /ENV\[IDENTITY_PROVIDER_HOST\], ENV\[IDENTITY_PROVIDER_PORT\], and ENV\[IDENTITY_PROVIDER_LDAP_BASE\] are required/
        }.to raise_error(StandardError)
      }
    end

    context 'missing ENV[IDENTITY_PROVIDER_PORT]' do
      before do
        ENV['IDENTITY_PROVIDER_HOST'] = identity_provider_attributes[:host]
        ENV['IDENTITY_PROVIDER_LDAP_BASE'] = identity_provider_attributes[:ldap_base]
      end
      it {
        expect {
          invoke_task epected_stderr: /ENV\[IDENTITY_PROVIDER_HOST\], ENV\[IDENTITY_PROVIDER_PORT\], and ENV\[IDENTITY_PROVIDER_LDAP_BASE\] are required/
        }.to raise_error(StandardError)
      }
    end

    context 'missing ENV[IDENTITY_PROVIDER_LDAP_BASE]' do
      before do
        ENV['IDENTITY_PROVIDER_HOST'] = identity_provider_attributes[:host]
        ENV['IDENTITY_PROVIDER_PORT'] = identity_provider_attributes[:port]
      end
      it {
        expect {
          invoke_task epected_stderr: /ENV\[IDENTITY_PROVIDER_HOST\], ENV\[IDENTITY_PROVIDER_PORT\], and ENV\[IDENTITY_PROVIDER_LDAP_BASE\] are required/
        }.to raise_error(StandardError)
      }
    end

    context 'required ENV present' do
      before do
        FactoryBot.attributes_for(:ldap_identity_provider).each do |key,value|
          ENV["IDENTITY_PROVIDER_#{key.upcase}"] = value
        end
      end

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
    let(:task_name) { "identity_provider:destroy" }
    let(:identity_provider) { FactoryBot.create(:ldap_identity_provider) }

    it { expect(subject.prerequisites).to  include("environment") }

    context 'missing ENV[IDENTITY_PROVIDER_ID]' do
      it {
        expect {
          invoke_task epected_stderr: /ENV\[IDENTITY_PROVIDER_ID\] is required/
        }.to raise_error(StandardError)
      }
    end

    context 'unknown IDENTITY_PROVIDER_ID' do
      before do
        ENV['IDENTITY_PROVIDER_ID'] = "#{SecureRandom.random_number}"
      end
      it {
        expect {
          invoke_task
        }.not_to raise_error
      }
    end

    context 'IDENTITY_PROVIDER_ID exists' do
      before do
        ENV['IDENTITY_PROVIDER_ID'] = "#{identity_provider.id}"
      end

      context 'specified identity_provider registered to an authentication_service' do
        let(:authentication_service) { FactoryBot.create(:openid_authentication_service, identity_provider: identity_provider) }
        it {
          expect {
            invoke_task epected_stderr: /identity_provider is registered to one or more authentication_services. use auth_service:identity_provider:remove/
          }.to raise_error(StandardError)
        }
      end

      context 'identity_provider not registered to an authentication_service' do
        it {
          expect {
            invoke_task
          }.to change{IdentityProvider.count}.by(-1)
        }
      end
    end
  end
end
