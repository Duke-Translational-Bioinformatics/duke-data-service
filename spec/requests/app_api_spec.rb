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
    include_context 'mocked StorageProvider'
    include_context 'mocked StorageProvider Interface'

    before do
      allow(StorageProvider).to receive(:default)
        .and_return(mocked_storage_provider)
      allow(mocked_storage_provider).to receive(:is_ready?)
        .and_return(true)
    end
  end
  before do
    ENV["GRAPHENEDB_URL"] = 'http://neo4j.db.host:7474'
  end

  describe 'app status' do
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

      context 'StorageProviderException' do
        let(:raised_error) { 'Some Error' }
        let(:status_error) { "StorageProvider error #{raised_error}" }
        include_context 'storage_provider setup'

        before do
          expect(mocked_storage_provider).to receive(:is_ready?)
            .and_raise(StorageProviderException, raised_error)
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
      let(:distributor_exchange_name) { ApplicationJob.distributor_exchange_name }
      let(:message_log_worker_queue_name) { MessageLogWorker.new.queue.name }

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
      it_behaves_like 'it requires exchange', :distributor_exchange_name

      it_behaves_like 'it requires queue', :message_log_worker_queue_name

      (ApplicationJob.descendants.collect {|d|
        [d.queue_name]
      }).flatten.uniq.each do |this_queue|
        let(:job_queue) { this_queue }
        it_behaves_like 'it requires queue', :job_queue
      end
    end

    it { expect(ApplicationJob.descendants).not_to be_empty }
  end #app status
end
