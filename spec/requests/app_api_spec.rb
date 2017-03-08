require 'rails_helper'

describe DDS::V1::AppAPI do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }

  describe 'app status', :vcr do
    context 'when rdbms is not seeded' do
      before do
        #AuthRoles are seeded
        expect(AuthRole.count).to be < 1
      end
      it_behaves_like 'a status error', 'rdbms is not seeded'
    end #when rdbms not seeded

    context 'authentication_service' do
      context 'is not created' do
        it_behaves_like 'a status error', 'authentication_service has not been created'
      end
    end #authentication_service

    context 'storage_provider' do
      context 'has not been created' do
        it_behaves_like 'a status error', 'storage_provider has not been created'
      end

      context 'has not registered its keys' do
        let(:swift_storage_provider) { FactoryGirl.create(:storage_provider, :swift) }
        before do
          expect(swift_storage_provider).to be_persisted
          #vcr records storage_provider.get_account_info with keys not registered
          resp = HTTParty.post(
            swift_storage_provider.storage_url,
            headers: swift_storage_provider.auth_header.merge({
              'X-Remove-Account-Meta-Temp-URL-Key' => 'yes',
              'X-Remove-Account-Meta-Temp-URL-Key-2' => 'yes'
            })
          )
        end
        it_behaves_like 'a status error', 'storage_provider has not registered its keys'
      end

      context 'is not connected' do
        let(:swift_storage_provider) { FactoryGirl.create(:storage_provider, :swift) }
        let!(:auth_roles) { FactoryGirl.create_list(:auth_role, 4) }
        let(:authentication_service) { FactoryGirl.create(:duke_authentication_service)}
        before do
          stub_request(:any, "#{swift_storage_provider.url_root}#{swift_storage_provider.auth_uri}").to_timeout
          expect(swift_storage_provider).to be_persisted
          expect(authentication_service).to be_persisted
        end
        it_behaves_like 'a status error', 'storage_provider is not connected'
      end
    end #storage_provider

    context 'graphdb' do
      context 'environment is not set' do
        before do
          ENV["GRAPHSTORY_URL"] = nil
        end
        it_behaves_like 'a status error', 'graphdb environment is not set'
      end
      # cannot test is not connected because vcr ignores all requests to neo4j
    end #graphdb

    context 'queue' do
      context 'environment is not set' do
        before do
          ENV["CLOUDAMQP_URL"] = nil
        end

        it_behaves_like 'a status error', 'queue environment is not set'
      end

      context 'is not connected' do
        before do
          ENV['CLOUDAMQP_URL'] = 'amqp://rabbit.host'
          expect(ApplicationJob).to receive(:conn)
          .and_raise(Bunny::TCPConnectionFailedForAllHosts)
        end
        it_behaves_like 'a status error', 'queue is not connected'
      end

      it_behaves_like 'it requires exchange', ApplicationJob.opts[:exchange]
      it_behaves_like 'it requires exchange', ApplicationJob.opts[:retry_error_exchange]
      it_behaves_like 'it requires exchange', ApplicationJob.distributor_exchange_name

      it_behaves_like 'it requires queue', MessageLogWorker.new.queue.name
      it_behaves_like 'it requires queue', "#{MessageLogWorker.new.queue.name}-retry"
      it_behaves_like 'it requires queue', ApplicationJob.opts[:retry_error_exchange]
      it_behaves_like 'it requires queue', ApplicationJob.opts[:retry_error_exchange]
      (ApplicationJob.descendants.collect {|d|
        [d.queue_name, "#{d.queue_name}-retry"]
      }).flatten.uniq.each do |this_queue|
        it_behaves_like 'it requires queue', this_queue
      end
    end

    context 'when properly integrated' do
      let!(:auth_roles) { FactoryGirl.create_list(:auth_role, 4) }
      let(:authentication_service) { FactoryGirl.create(:duke_authentication_service)}
      let(:swift_storage_provider) { FactoryGirl.create(:storage_provider, :swift) }

      before do
        WebMock.reset!
        ENV["GRAPHSTORY_URL"] = 'http://neo4j.db.host:7474'
        swift_storage_provider.register_keys
      end
      include_context 'expected bunny exchanges and queues'

      it {
        expect(authentication_service).to be_persisted
        get '/api/v1/app/status', json_headers
        expect(response.status).to eq(200)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        returned_configs = JSON.parse(response.body)
        expect(returned_configs).to be_a Hash

        expect(returned_configs).to have_key('status')
        expect(returned_configs['status']).to eq('ok')

        expect(returned_configs).to have_key('environment')
        expect(returned_configs['environment']).to eq("#{Rails.env}")
      }
    end #when properly integrated
  end #app status
end
