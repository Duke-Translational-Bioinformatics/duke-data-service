require 'rails_helper'

describe DDS::V1::AppAPI do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }

  describe 'app status' do
    describe 'when AuthRoles are seeded' do
      let!(:auth_roles) { FactoryGirl.create_list(:auth_role, 4) }

      it 'should return {status: ok}' do
        get '/api/v1/app/status', json_headers
        expect(response.status).to eq(200)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        returned_configs = JSON.parse(response.body)
        expect(returned_configs).to be_a Hash
        expect(returned_configs).to have_key('status')
        expect(returned_configs['status']).to eq('ok')
      end
    end
    describe 'when AuthRoles are not seeded' do
      it 'should return response.status 503' do
        expect(AuthRole.count).to be < 1
        get '/api/v1/app/status', json_headers
        expect(response.status).to eq(503)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        returned_configs = JSON.parse(response.body)
        expect(returned_configs).to be_a Hash
        expect(returned_configs).to have_key('status')
        expect(returned_configs['status']).to eq('error')
        expect(returned_configs).to have_key('message')
        expect(returned_configs['message']).to eq('database not seeded')
      end
    end
  end
end
