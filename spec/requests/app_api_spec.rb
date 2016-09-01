require 'rails_helper'

describe DDS::V1::AppAPI do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }

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
      context 'environment is not set' do
        before do
          ENV['AUTH_SERVICE_ID'] = nil
          ENV['AUTH_SERVICE_BASE_URI'] = nil
          ENV['AUTH_SERVICE_NAME'] = 'Duke Authentication Service'
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
          expect(returned_configs).to have_key('authentication_service')
          expect(returned_configs['authentication_service']).to eq('environment is not set')
        end
      end

      context 'is not created' do
        before do
          ENV['AUTH_SERVICE_ID'] = '342c075a-7aca-4c35-b3f5-29f043884b5b'
          ENV['AUTH_SERVICE_BASE_URI'] = 'https://localhost:3000'
          ENV['AUTH_SERVICE_NAME'] = 'Duke Authentication Service'
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
          expect(returned_configs).to have_key('authentication_service')
          expect(returned_configs['authentication_service']).to eq('has not been created')
        end
      end
    end #authentication_service

    context 'storage_provider' do
      context 'environment is not set' do
        before do
          ENV['SWIFT_DISPLAY_NAME'] = nil
          ENV['SWIFT_DESCRIPTION'] = nil
          ENV['SWIFT_ACCT'] = nil
          ENV['SWIFT_URL_ROOT'] = nil
          ENV['SWIFT_VERSION'] = nil
          ENV['SWIFT_AUTH_URI'] = nil
          ENV['SWIFT_USER'] = nil
          ENV['SWIFT_PASS'] = nil
          ENV['SWIFT_PRIMARY_KEY'] = nil
          ENV['SWIFT_SECONDARY_KEY'] = nil
          ENV['SWIFT_CHUNK_HASH_ALGORITHM'] = nil
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
          expect(returned_configs).to have_key('storage_provider')
          expect(returned_configs['storage_provider']).to eq('environment is not set')
        end
      end

      context 'has not been created' do
        before do
          ENV['SWIFT_DISPLAY_NAME'] = 'OIT Swift'
          ENV['SWIFT_DESCRIPTION'] = 'Duke OIT Swift Service'
          ENV['SWIFT_ACCT'] = 'AUTH_test'
          ENV['SWIFT_URL_ROOT'] = 'http://swift.local:12345'
          ENV['SWIFT_VERSION'] = 'v1'
          ENV['SWIFT_AUTH_URI'] = '/auth/v1.0'
          ENV['SWIFT_USER'] = 'test:tester'
          ENV['SWIFT_PASS'] = 'testing'
          ENV['SWIFT_PRIMARY_KEY'] = '5ea5d3ec4111586633e58b60ac1f542c96778ee51bce23602368ab5303df63db52239993cef8881fb78e0b39346d2ac11aac833b899aa4283dc3bb0659c2ef05'
          ENV['SWIFT_SECONDARY_KEY'] = '1e8de2158d75b148f96d563e332b450fb7210b57f4bd76b8588d6dbc5cf445f47dc71bd4cf50d2693f144ba423ef4389a83757f4fdcecb35943ee67d2be81c0f'
          ENV['SWIFT_CHUNK_HASH_ALGORITHM'] = 'md5'
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
          expect(returned_configs).to have_key('storage_provider')
          expect(returned_configs['storage_provider']).to eq('has not been created')
        end
      end

      context 'has not registered its keys' do
        let(:swift_storage_provider) { FactoryGirl.create(:storage_provider, :swift) }
        before do
          ENV['SWIFT_DISPLAY_NAME'] = 'OIT Swift'
          ENV['SWIFT_DESCRIPTION'] = 'Duke OIT Swift Service'
          ENV['SWIFT_ACCT'] = 'AUTH_test'
          ENV['SWIFT_URL_ROOT'] = 'http://swift.local:12345'
          ENV['SWIFT_VERSION'] = 'v1'
          ENV['SWIFT_AUTH_URI'] = '/auth/v1.0'
          ENV['SWIFT_USER'] = 'test:tester'
          ENV['SWIFT_PASS'] = 'testing'
          ENV['SWIFT_PRIMARY_KEY'] = '5ea5d3ec4111586633e58b60ac1f542c96778ee51bce23602368ab5303df63db52239993cef8881fb78e0b39346d2ac11aac833b899aa4283dc3bb0659c2ef05'
          ENV['SWIFT_SECONDARY_KEY'] = '1e8de2158d75b148f96d563e332b450fb7210b57f4bd76b8588d6dbc5cf445f47dc71bd4cf50d2693f144ba423ef4389a83757f4fdcecb35943ee67d2be81c0f'
          ENV['SWIFT_CHUNK_HASH_ALGORITHM'] = 'md5'
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
        let(:authentication_service) { FactoryGirl.create(:authentication_service)}
        before do
          ENV['AUTH_SERVICE_ID'] = '342c075a-7aca-4c35-b3f5-29f043884b5b'
          ENV['AUTH_SERVICE_BASE_URI'] = 'https://localhost:3000'
          ENV['AUTH_SERVICE_NAME'] = 'Duke Authentication Service'
          ENV['SWIFT_DISPLAY_NAME'] = 'OIT Swift'
          ENV['SWIFT_DESCRIPTION'] = 'Duke OIT Swift Service'
          ENV['SWIFT_ACCT'] = 'AUTH_test'
          ENV['SWIFT_URL_ROOT'] = 'http://swift.local:12345'
          ENV['SWIFT_VERSION'] = 'v1'
          ENV['SWIFT_AUTH_URI'] = '/auth/v1.0'
          ENV['SWIFT_USER'] = 'test:tester'
          ENV['SWIFT_PASS'] = 'testing'
          ENV['SWIFT_PRIMARY_KEY'] = '5ea5d3ec4111586633e58b60ac1f542c96778ee51bce23602368ab5303df63db52239993cef8881fb78e0b39346d2ac11aac833b899aa4283dc3bb0659c2ef05'
          ENV['SWIFT_SECONDARY_KEY'] = '1e8de2158d75b148f96d563e332b450fb7210b57f4bd76b8588d6dbc5cf445f47dc71bd4cf50d2693f144ba423ef4389a83757f4fdcecb35943ee67d2be81c0f'
          ENV['SWIFT_CHUNK_HASH_ALGORITHM'] = 'md5'
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

    context 'when properly integrated' do
      let!(:auth_roles) { FactoryGirl.create_list(:auth_role, 4) }
      let(:authentication_service) { FactoryGirl.create(:authentication_service)}
      let(:swift_storage_provider) { FactoryGirl.create(:storage_provider, :swift) }

      before do
        WebMock.reset!
        ENV['AUTH_SERVICE_ID'] = '342c075a-7aca-4c35-b3f5-29f043884b5b'
        ENV['AUTH_SERVICE_BASE_URI'] = 'https://localhost:3000'
        ENV['AUTH_SERVICE_NAME'] = 'Duke Authentication Service'
        ENV['SWIFT_DISPLAY_NAME'] = 'OIT Swift'
        ENV['SWIFT_DESCRIPTION'] = 'Duke OIT Swift Service'
        ENV['SWIFT_ACCT'] = 'AUTH_test'
        ENV['SWIFT_URL_ROOT'] = 'http://swift.local:12345'
        ENV['SWIFT_VERSION'] = 'v1'
        ENV['SWIFT_AUTH_URI'] = '/auth/v1.0'
        ENV['SWIFT_USER'] = 'test:tester'
        ENV['SWIFT_PASS'] = 'testing'
        ENV['SWIFT_PRIMARY_KEY'] = '5ea5d3ec4111586633e58b60ac1f542c96778ee51bce23602368ab5303df63db52239993cef8881fb78e0b39346d2ac11aac833b899aa4283dc3bb0659c2ef05'
        ENV['SWIFT_SECONDARY_KEY'] = '1e8de2158d75b148f96d563e332b450fb7210b57f4bd76b8588d6dbc5cf445f47dc71bd4cf50d2693f144ba423ef4389a83757f4fdcecb35943ee67d2be81c0f'
        ENV['SWIFT_CHUNK_HASH_ALGORITHM'] = 'md5'
        ENV["GRAPHSTORY_URL"] = 'http://neo4j.db.host:7474'
        swift_storage_provider.register_keys
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
      end
    end #when properly integrated
  end #app status
end
