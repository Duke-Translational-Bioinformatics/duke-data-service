require 'rails_helper'

describe DDS::V1::AppAPI do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }
  let(:queue_prefix) { Rails.application.config.active_job.queue_name_prefix }
  let(:queue_prefix_delimiter) { Rails.application.config.active_job.queue_name_delimiter }

  describe 'app status', :vcr do
    context 'when rdbms is not seeded' do
      it 'should return response.status 503' do
        #AuthRoles are seeded
        expect(AuthRole.count).to be < 1
        get '/api/v1/app/status', json_headers
        expect(response.status).to eq(503)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        returned_configs = JSON.parse(response.body)
        expect(returned_configs).to be_a Hash
        expect(returned_configs).to have_key('status')
        expect(returned_configs['status']).to eq('error')
        expect(returned_configs).to have_key('rdbms')
        expect(returned_configs['rdbms']).to eq('is not seeded')
      end
    end #when rdbms not seeded

    context 'authentication_service' do
      context 'is not created' do
        it 'should return response.status 503' do
          get '/api/v1/app/status', json_headers
          expect(response.status).to eq(503)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
          returned_configs = JSON.parse(response.body)
          expect(returned_configs).to be_a Hash
          expect(returned_configs).to have_key('status')
          expect(returned_configs['status']).to eq('error')
          expect(returned_configs).to have_key('authentication_service')
          expect(returned_configs['authentication_service']).to eq('has not been created')
        end
      end
    end #authentication_service

    context 'storage_provider' do
      context 'has not been created' do
        it 'should return response.status 503' do
          get '/api/v1/app/status', json_headers
          expect(response.status).to eq(503)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
          returned_configs = JSON.parse(response.body)
          expect(returned_configs).to be_a Hash
          expect(returned_configs).to have_key('status')
          expect(returned_configs['status']).to eq('error')
          expect(returned_configs).to have_key('storage_provider')
          expect(returned_configs['storage_provider']).to eq('has not been created')
        end
      end

      context 'has not registered its keys' do
        let(:swift_storage_provider) { FactoryGirl.create(:storage_provider, :swift) }
        before do
          resp = HTTParty.post(
            swift_storage_provider.storage_url,
            headers: swift_storage_provider.auth_header.merge({
              'X-Remove-Account-Meta-Temp-URL-Key' => 'yes',
              'X-Remove-Account-Meta-Temp-URL-Key-2' => 'yes'
            })
          )
        end
        it 'should return response.status 503' do
          expect(swift_storage_provider).to be_persisted
          #vcr records storage_provider.get_account_info with keys not registered
          get '/api/v1/app/status', json_headers
          expect(response.status).to eq(503)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
          returned_configs = JSON.parse(response.body)
          expect(returned_configs).to be_a Hash
          expect(returned_configs).to have_key('status')
          expect(returned_configs['status']).to eq('error')
          expect(returned_configs).to have_key('storage_provider')
          expect(returned_configs['storage_provider']).to eq('has not registered its keys')
        end
      end

      context 'is not connected' do
        let(:swift_storage_provider) { FactoryGirl.create(:storage_provider, :swift) }
        let!(:auth_roles) { FactoryGirl.create_list(:auth_role, 4) }
        let(:authentication_service) { FactoryGirl.create(:duke_authentication_service)}
        before do
          stub_request(:any, "#{swift_storage_provider.url_root}#{swift_storage_provider.auth_uri}").to_timeout
        end
        it 'should return response.status 503' do
          expect(swift_storage_provider).to be_persisted
          expect(authentication_service).to be_persisted
          get '/api/v1/app/status', json_headers
          expect(response.status).to eq(503)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
          returned_configs = JSON.parse(response.body)
          expect(returned_configs).to be_a Hash
          expect(returned_configs).to have_key('status')
          expect(returned_configs['status']).to eq('error')
          expect(returned_configs).to have_key('storage_provider')
          expect(returned_configs['storage_provider']).to eq('is not connected')
        end
      end
    end #storage_provider

    context 'graphdb' do
      context 'environment is not set' do
        before do
          ENV["GRAPHSTORY_URL"] = nil
        end
        it 'should return response.status 503' do
          get '/api/v1/app/status', json_headers
          expect(response.status).to eq(503)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
          returned_configs = JSON.parse(response.body)
          expect(returned_configs).to be_a Hash
          expect(returned_configs).to have_key('status')
          expect(returned_configs['status']).to eq('error')
          expect(returned_configs).to have_key('graphdb')
          expect(returned_configs['graphdb']).to eq('environment is not set')
        end
      end
      # cannot test is not connected because vcr ignores all requests to neo4j
    end #graphdb

    context 'queue' do
      context 'environment is not set' do
        before do
          ENV["CLOUDAMQP_URL"] = nil
        end
        it 'should return response.status 503' do
          get '/api/v1/app/status', json_headers
          expect(response.status).to eq(503)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
          returned_configs = JSON.parse(response.body)
          expect(returned_configs).to be_a Hash
          expect(returned_configs).to have_key('status')
          expect(returned_configs['status']).to eq('error')
          expect(returned_configs).to have_key('queue')
          expect(returned_configs['queue']).to eq('environment is not set')
        end
      end

      context 'is not connected' do
        before do
          ENV['CLOUDAMQP_URL'] = 'amqp://rabbit.host'
        end
        it 'should return response.status 503' do
          expect(ApplicationJob).to receive(:conn)
            .and_raise(Bunny::TCPConnectionFailedForAllHosts)
          get '/api/v1/app/status', json_headers
          expect(response.status).to eq(503)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
          returned_configs = JSON.parse(response.body)
          expect(returned_configs).to be_a Hash
          expect(returned_configs).to have_key('status')
          expect(returned_configs['status']).to eq('error')
          expect(returned_configs).to have_key('queue')
          expect(returned_configs['queue']).to eq('is not connected')
        end
      end

      context 'missing expected exchange' do
        before do
          ENV['CLOUDAMQP_URL'] = 'amqp://rabbit.host'
          queue_names = (ApplicationJob.descendants.collect {|d| d.queue_name }).uniq
          mocked_bunny_session = instance_double(BunnyMock::Session)
          [ApplicationJob.opts[:exchange], ApplicationJob.distributor_exchange_name].each do |this_exchange|
            should_exist = this_exchange != expected_exchange
            allow(mocked_bunny_session).to receive(:exchange_exists?)
              .with(this_exchange)
              .and_return(should_exist)
          end
          ['message_log'].concat(queue_names).each do |expected_queue|
            allow(mocked_bunny_session).to receive(:queue_exists?)
              .with(expected_queue)
              .and_return(true)
          end
          allow(ApplicationJob).to receive(:conn).and_return(mocked_bunny_session)
        end

        context ApplicationJob.opts[:exchange] do
          let(:expected_exchange) { ApplicationJob.opts[:exchange] }
          it {
            get '/api/v1/app/status', json_headers
            expect(response.status).to eq(503)
            expect(response.body).to be
            expect(response.body).not_to eq('null')
            returned_configs = JSON.parse(response.body)
            expect(returned_configs).to be_a Hash
            expect(returned_configs).to have_key('status')
            expect(returned_configs['status']).to eq('error')
            expect(returned_configs).to have_key('queue')
            expect(returned_configs['queue']).to match(/is missing expected exchange.*#{expected_exchange}/)
          }
        end

        context ApplicationJob.distributor_exchange_name do
          let(:expected_exchange) { ApplicationJob.distributor_exchange_name }
          it {
            get '/api/v1/app/status', json_headers
            expect(response.status).to eq(503)
            expect(response.body).to be
            expect(response.body).not_to eq('null')
            returned_configs = JSON.parse(response.body)
            expect(returned_configs).to be_a Hash
            expect(returned_configs).to have_key('status')
            expect(returned_configs['status']).to eq('error')
            expect(returned_configs).to have_key('queue')
            expect(returned_configs['queue']).to match(/is missing expected exchange.*#{expected_exchange}/)
          }
        end
      end

      context 'missing expected queues' do
        before do
          ENV['CLOUDAMQP_URL'] = 'amqp://rabbit.host'
          silence_warnings do
            Rails.application.eager_load! unless Rails.application.config.eager_load
          end
          queue_names = (ApplicationJob.descendants.collect {|d| d.queue_name }).uniq
          mocked_bunny_session = instance_double(BunnyMock::Session)

          [ApplicationJob.opts[:exchange], ApplicationJob.distributor_exchange_name].each do |expected_exchange|
            allow(mocked_bunny_session).to receive(:exchange_exists?)
              .with(expected_exchange)
              .and_return(true)
          end

          ['message_log'].concat(queue_names).each do |this_queue|
            if this_queue.include? queue_prefix
              should_exist = "#{queue_prefix}#{queue_prefix_delimiter}#{expected_queue}" != this_queue
            else
              should_exist = expected_queue != this_queue
            end
            allow(mocked_bunny_session).to receive(:queue_exists?)
              .with(this_queue)
              .and_return(should_exist)
          end
          allow(ApplicationJob).to receive(:conn).and_return(mocked_bunny_session)
        end

        context 'message_log' do
          let(:expected_queue) { 'message_log' }

          it {
            get '/api/v1/app/status', json_headers
            expect(response.status).to eq(503)
            expect(response.body).to be
            expect(response.body).not_to eq('null')
            returned_configs = JSON.parse(response.body)
            expect(returned_configs).to be_a Hash
            expect(returned_configs).to have_key('status')
            expect(returned_configs['status']).to eq('error')
            expect(returned_configs).to have_key('queue')
            expect(returned_configs['queue']).to match(/is missing expected queues.*#{expected_queue}/)
          }
        end

        context 'child_deletion' do
          let(:expected_queue) { 'child_deletion' }

          it {
            get '/api/v1/app/status', json_headers
            expect(response.status).to eq(503)
            expect(response.body).to be
            expect(response.body).not_to eq('null')
            returned_configs = JSON.parse(response.body)
            expect(returned_configs).to be_a Hash
            expect(returned_configs).to have_key('status')
            expect(returned_configs['status']).to eq('error')
            expect(returned_configs).to have_key('queue')
            expect(returned_configs['queue']).to match(/is missing expected queues.*#{expected_queue}/)
          }
        end

        context 'project_storage_provider_initialization' do
          let(:expected_queue) { 'project_storage_provider_initialization' }

          it {
            get '/api/v1/app/status', json_headers
            expect(response.status).to eq(503)
            expect(response.body).to be
            expect(response.body).not_to eq('null')
            returned_configs = JSON.parse(response.body)
            expect(returned_configs).to be_a Hash
            expect(returned_configs).to have_key('status')
            expect(returned_configs['status']).to eq('error')
            expect(returned_configs).to have_key('queue')
            expect(returned_configs['queue']).to match(/is missing expected queues.*#{expected_queue}/)
          }
        end
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
        ENV["CLOUDAMQP_URL"] = Faker::Internet.slug
        queue_names = (ApplicationJob.descendants.collect {|d| d.queue_name }).uniq
        mocked_bunny_session = instance_double(BunnyMock::Session)

        [ApplicationJob.opts[:exchange], ApplicationJob.distributor_exchange_name].each do |expected_exchange|
          allow(mocked_bunny_session).to receive(:exchange_exists?)
            .with(expected_exchange)
            .and_return(true)
        end

        ['message_log'].concat(queue_names).each do |expected_queue|
          allow(mocked_bunny_session).to receive(:queue_exists?)
            .with(expected_queue)
            .and_return(true)
        end
        allow(ApplicationJob).to receive(:conn).and_return(mocked_bunny_session)
      end

      it 'should return {status: ok}' do
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

        expect(returned_configs).to have_key('rdbms')
        expect(returned_configs['rdbms']).to eq('ok')

        expect(returned_configs).to have_key('authentication_service')
        expect(returned_configs['authentication_service']).to eq('ok')

        expect(returned_configs).to have_key('storage_provider')
        expect(returned_configs['storage_provider']).to eq('ok')

        expect(returned_configs).to have_key('graphdb')
        expect(returned_configs['graphdb']).to eq('ok')

        expect(returned_configs).to have_key('queue')
        expect(returned_configs['queue']).to eq('ok')
      end
    end #when properly integrated
  end #app status
end
