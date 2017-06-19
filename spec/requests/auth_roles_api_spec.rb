require 'rails_helper'

describe DDS::V1::AuthRolesAPI do
  include_context 'with authentication'

  let(:context) { 'project' }
  let(:auth_role) { FactoryGirl.create(:auth_role, contexts: [context]) }
  let(:other_context_auth_role) { FactoryGirl.create(:auth_role, contexts: ['system']) }
  let(:resource) { auth_role }
  let(:resource_class) { AuthRole }
  let(:resource_serializer) { AuthRoleSerializer }

  describe 'List authorization roles' do
    let(:url) {"/api/v1/auth_roles"}

    describe 'for a context' do
      let(:payload) {{context: context}}
      subject { get(url, params: payload, headers: headers) }

      it_behaves_like 'a listable resource' do
        it 'should only include authorization_roles for the given context' do
          expect(auth_role).to be_persisted
          expect(other_context_auth_role).to be_persisted
          is_expected.to eq(200)
          expect(response.body).not_to eq('null')
          expect(response.body).to include(resource_serializer.new(resource).to_json)
          expect(response.body).not_to include(resource_serializer.new(other_context_auth_role).to_json)
        end

        it 'should only return false or true for is_deprecated' do
          is_expected.to eq(200)
          response_json = JSON.parse(response.body)
          expect(response_json['results'].first['is_deprecated']).to_not be(nil)
          expect(response_json['results'].first['is_deprecated']).to be(false)
          expect(response.body).not_to eq('null')
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'

      describe 'that does not exist' do
        let!(:payload) {{context: 'notexists'}}
        it 'should return 404 with error' do
          is_expected.to eq(404)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
          response_json = JSON.parse(response.body)
          expect(response_json).to have_key('error')
          expect(response_json['error']).to eq('404')
          expect(response_json).to have_key('code')
          expect(response_json['code']).to eq('not_provided')
          expect(response_json).to have_key('reason')
          expect(response_json['reason']).to eq("Unknown Context")
          expect(response_json).to have_key('suggestion')
          expect(response_json['suggestion']).to eq("Context should be either project or system")
        end
      end
    end

    describe 'without a context' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a listable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'
    end
  end

  describe 'View authorization role details' do
    let(:url) {"/api/v1/auth_roles/#{resource_id}"}
    let(:resource_id) { resource.id }
    describe 'GET' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'

      it_behaves_like 'an identified resource' do
        let(:resource_id) { "doesNotExist" }
      end
    end
  end
end
