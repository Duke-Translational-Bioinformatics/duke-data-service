require 'rails_helper'

describe DDS::V1::SystemPermissionsAPI do
  include_context 'with authentication'

  let(:system_permission) { FactoryGirl.create(:system_permission) }
  let(:other_permission) { FactoryGirl.create(:system_permission) }
  let!(:auth_role) { FactoryGirl.create(:auth_role, :system) }
  let(:other_user) { FactoryGirl.create(:user) }
  let!(:invalid_auth_role) { FactoryGirl.create(:auth_role) }

  let(:resource_class) { SystemPermission }
  let(:resource_serializer) { SystemPermissionSerializer }
  let!(:resource) { system_permission }
  let!(:resource_permission) { FactoryGirl.create(:system_permission, user: current_user) }
  let(:resource_user) { resource.user }

  describe 'System Permissions collection' do
    let(:url) { "/api/v1/system/permissions" }

    describe 'GET' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a listable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource'
    end
  end

  describe 'System Permission instance' do
    let(:url) { "/api/v1/system/permissions/#{resource_user_id}" }
    let(:resource_user_id) { resource_user.id }

    describe 'PUT' do
      subject { put(url, params: payload.to_json, headers: headers) }
      let!(:payload) {{
        auth_role: {id: auth_role.id}
      }}

      it_behaves_like 'a creatable resource' do
        let(:expected_response_status) {200}
        let(:resource_user) { other_user }
        let(:new_object) {
          resource_class.find_by(user: resource_user)
        }
      end

      it_behaves_like 'an updatable resource'

      it_behaves_like 'a validated resource' do
        let!(:payload) {{
          auth_role: {id: invalid_auth_role.id}
        }}
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an identified resource' do
        let(:resource_user_id) { "doesNotExist" }
        let(:resource_class) {'User'}
      end
      it_behaves_like 'an identified resource' do
        let!(:payload) {{
          auth_role: {id: 'invalid_role'}
        }}
        let(:resource_class) {'AuthRole'}
      end
      it_behaves_like 'a software_agent accessible resource'
    end

    describe 'GET' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an identified resource' do
        let(:resource_user_id) { "doesNotExist" }
        let(:resource_class) {'User'}
      end
      it_behaves_like 'an identified resource' do
        let(:resource_user) {FactoryGirl.create(:user)}
      end

      it_behaves_like 'a software_agent accessible resource'

      context 'system_permission for current_user' do
        let!(:resource) { resource_permission }
        let(:resource_user) { current_user }

        it_behaves_like 'an authorized resource'
      end
    end

    describe 'DELETE' do
      subject { delete(url, headers: headers) }

      it_behaves_like 'a removable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an identified resource' do
        let(:resource_user_id) { "doesNotExist" }
        let(:resource_class) {'User'}
      end
      it_behaves_like 'an identified resource' do
        let(:resource_user) {FactoryGirl.create(:user)}
      end
      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 204 }
      end
    end
  end
end
