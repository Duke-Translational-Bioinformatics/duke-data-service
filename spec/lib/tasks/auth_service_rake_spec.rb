require 'rails_helper'
if Rails.version > '5.0.0'
  require 'active_support/testing/stream'
  include ActiveSupport::Testing::Stream
end

describe "auth_service", :if => ENV['TEST_RAKE_AUTH_SERVICE'] do

  describe "auth_service:duke:create" do
    include_context "rake"
    let(:rake_task_name) { "auth_service:duke:create" }
    let(:resource_class) { DukeAuthenticationService }
    let(:required_env) { %w(
        AUTH_SERVICE_SERVICE_ID
        AUTH_SERVICE_BASE_URI
        AUTH_SERVICE_NAME
      )
    }

    before do
      FactoryGirl.attributes_for(:duke_authentication_service).each do |key,value|
        ENV["AUTH_SERVICE_#{key.upcase}"] = value
      end
    end
    it_behaves_like 'an authentication_service:create task'
  end

  describe 'auth_service:duke:destroy' do
    include_context "rake"
    let(:rake_task_name) { "auth_service:duke:destroy" }
    let(:resource_class) { DukeAuthenticationService }

    before do
      FactoryGirl.attributes_for(:openid_authentication_service).each do |key,value|
        ENV["AUTH_SERVICE_#{key.upcase}"] = value
      end
    end
    it_behaves_like 'an authentication_service:destroy task'
  end

  describe "auth_service:openid:create" do
    include_context "rake"
    let(:rake_task_name) { "auth_service:openid:create" }
    let(:resource_class) { OpenidAuthenticationService }
    let(:required_env) { %w(
        AUTH_SERVICE_SERVICE_ID
        AUTH_SERVICE_BASE_URI
        AUTH_SERVICE_NAME
      )
    }

    before do
      FactoryGirl.attributes_for(:duke_authentication_service).each do |key,value|
        ENV["AUTH_SERVICE_#{key.upcase}"] = value
      end
    end
    it_behaves_like 'an authentication_service:create task'
  end

  describe 'auth_service:openid:destroy' do
    include_context "rake"
    let(:rake_task_name) { "auth_service:openid:destroy" }
    let(:resource_class) { OpenidAuthenticationService }

    before do
      FactoryGirl.attributes_for(:openid_authentication_service).each do |key,value|
        ENV["AUTH_SERVICE_#{key.upcase}"] = value
      end
    end
    it_behaves_like 'an authentication_service:destroy task'
  end

  describe 'auth_service:transfer_default' do
    include_context "rake"
    let(:task_name) { "auth_service:transfer_default" }
    let(:invoke_task) { silence_stream(STDOUT) { subject.invoke } }
    let(:default_authentication_service) { FactoryGirl.create(:duke_authentication_service, :default) }
    let(:non_default_authentication_service) { FactoryGirl.create(:openid_authentication_service) }

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
    let(:invoke_task) { silence_stream(STDOUT) { subject.invoke } }

    context 'missing ENV[AUTH_SERVICE_SERVICE_ID]' do
      it {
        expect {
          expect {
            invoke_task
          }.to output(/AUTH_SERVICE_SERVICE_ID environment variable is required/).to_stderr
        }.to raise_error(StandardError)
      }
    end

    context 'specified service does not exist' do
      before do
        ENV['AUTH_SERVICE_SERVICE_ID'] = SecureRandom.uuid
      end
      it {
        expect {
          expect {
            invoke_task
          }.to output(/AUTH_SERVICE_SERVICE_ID is not a registered service/).to_stderr
        }.to raise_error(StandardError)
      }
    end

    context 'specified service is already default' do
      let(:authentication_service) { FactoryGirl.create(:duke_authentication_service, :default) }
      before do
        ENV['AUTH_SERVICE_SERVICE_ID'] = authentication_service.service_id
      end

      it {
        expect {
          expect {
            invoke_task
          }.to output(/AUTH_SERVICE_SERVICE_ID service is already default/).to_stderr
        }.not_to raise_error
      }
    end

    context 'specified service is not already default' do
      let(:authentication_service) { FactoryGirl.create(:openid_authentication_service) }

      before do
        ENV['AUTH_SERVICE_SERVICE_ID'] = authentication_service.service_id
      end

      context 'another default service already exists' do
        let(:default_authentication_service) { FactoryGirl.create(:duke_authentication_service, :default) }
        it {
          expect {
            expect {
              invoke_task
            }.to output(Regexp.new("Service #{default_authentication_service.service_id} is already default. Use auth_service_transfer_default instead")).to_stderr
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
end
