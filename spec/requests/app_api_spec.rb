require 'rails_helper'

describe DDS::V1::AppAPI do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }

  include_context 'with sneakers'
  shared_context 'seeded rdbms' do
    let!(:auth_roles) { FactoryBot.create_list(:auth_role, 4) }
  end
  shared_context 'authentication_service created' do
    let(:authentication_service) { FactoryBot.create(:duke_authentication_service)}
    before { expect(authentication_service).to be_persisted }
  end
  shared_context 'storage_provider setup' do
    let(:swift_storage_provider) { FactoryBot.create(:swift_storage_provider) }

    before do
      swift_storage_provider.register_keys
    end
  end
  before do
    ENV["GRAPHENEDB_URL"] = 'http://neo4j.db.host:7474'
  end

  describe 'app status', :vcr do
    context 'when properly integrated' do
      include_context 'seeded rdbms'
      include_context 'authentication_service created'
      include_context 'storage_provider setup'
      include_context 'expected bunny exchanges and queues'

      it {
        expect(Sneakers::CONFIG[:connection]).to receive(:start)
         .and_call_original
        get '/api/v1/app/status', params: json_headers
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

    context 'when rdbms is not seeded' do
      include_context 'authentication_service created'
      include_context 'storage_provider setup'
      include_context 'expected bunny exchanges and queues'

      let(:status_error) { 'rdbms is not seeded' }
      before do
        #AuthRoles are seeded
        expect(AuthRole.count).to be < 1
      end
      it_behaves_like 'a status error', :status_error
    end #when rdbms not seeded

    context 'authentication_service' do
      include_context 'seeded rdbms'
      include_context 'storage_provider setup'
      include_context 'expected bunny exchanges and queues'

      context 'is not created' do
        let(:status_error) { 'authentication_service has not been created' }
        it_behaves_like 'a status error', :status_error
      end
    end #authentication_service

    context 'storage_provider' do
      include_context 'seeded rdbms'
      include_context 'authentication_service created'
      include_context 'expected bunny exchanges and queues'

      context 'has not been created' do
        let(:status_error) { 'storage_provider has not been created' }
        it_behaves_like 'a status error', :status_error
      end

      context 'has not registered its keys' do
        let(:status_error) { 'storage_provider has not registered its keys' }
        let(:swift_storage_provider) { FactoryBot.create(:swift_storage_provider) }
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
        it_behaves_like 'a status error', :status_error
      end

      context 'is not connected' do
        let(:status_error) { 'storage_provider is not connected' }
        let(:swift_storage_provider) { FactoryBot.create(:swift_storage_provider) }
        let!(:auth_roles) { FactoryBot.create_list(:auth_role, 4) }
        let(:authentication_service) { FactoryBot.create(:duke_authentication_service)}
        before do
          stub_request(:any, "#{swift_storage_provider.url_root}#{swift_storage_provider.auth_uri}").to_timeout
          expect(swift_storage_provider).to be_persisted
          expect(authentication_service).to be_persisted
          allow(Rails.logger).to receive(:error).with(/^StorageProvider error/)
        end
        after do
          WebMock.reset!
        end
        it_behaves_like 'a status error', :status_error
      end
    end #storage_provider

    context 'graphdb' do
      include_context 'seeded rdbms'
      include_context 'authentication_service created'
      include_context 'storage_provider setup'
      include_context 'expected bunny exchanges and queues'

      context 'environment is not set' do
        let(:status_error) { 'graphdb environment is not set' }
        before do
          ENV["GRAPHENEDB_URL"] = nil
        end
        it_behaves_like 'a status error', :status_error
      end
      # cannot test is not connected because vcr ignores all requests to neo4j
    end #graphdb

    context 'queue' do
      include_context 'seeded rdbms'
      include_context 'authentication_service created'
      include_context 'storage_provider setup'

      let(:gateway_exchange_name) { Sneakers::CONFIG[:exchange] }
      let(:retry_error_exchange_name) { Sneakers::CONFIG[:retry_error_exchange] }
      let(:distributor_exchange_name) { ApplicationJob.distributor_exchange_name }
      let(:message_log_worker_queue_name) { MessageLogWorker.new.queue.name }
      let(:message_log_worker_retry_queue_name) { "#{MessageLogWorker.new.queue.name}-retry" }
      let(:retry_error_queue_name) { Sneakers::CONFIG[:retry_error_exchange] }

      context 'environment is not set' do
        let(:status_error) { 'queue environment is not set' }
        before do
          ENV["CLOUDAMQP_URL"] = nil
        end

        it_behaves_like 'a status error', :status_error
      end

      context 'is not connected' do
        let(:status_error) { 'queue is not connected' }
        let(:bunny_session) { Sneakers::CONFIG[:connection] }
        before do
          ENV['CLOUDAMQP_URL'] = 'amqp://rabbit.host'
          expect(bunny_session).to receive(:exchange_exists?).and_raise(
            Bunny::TCPConnectionFailedForAllHosts
          )
          allow(Rails.logger).to receive(:error).with(/^RabbitMQ Connection error/)
        end
        it_behaves_like 'a status error', :status_error
      end

      it_behaves_like 'it requires exchange', :gateway_exchange_name
      it_behaves_like 'it requires exchange', :retry_error_exchange_name
      it_behaves_like 'it requires exchange', :distributor_exchange_name

      it_behaves_like 'it requires queue', :message_log_worker_queue_name
      it_behaves_like 'it requires queue', :message_log_worker_retry_queue_name
      it_behaves_like 'it requires queue', :retry_error_queue_name

      (ApplicationJob.descendants.collect {|d|
        [d.queue_name, "#{d.queue_name}-retry"]
      }).flatten.uniq.each do |this_queue|
        let(:job_queue) { this_queue }
        it_behaves_like 'it requires queue', :job_queue
      end
    end

    it { expect(ApplicationJob.descendants).not_to be_empty }
  end #app status
end
