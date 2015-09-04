require 'rails_helper'

describe DDS::V1::ProjectPermissionsAPI do
  include_context 'with authentication'

  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:other_permission) { FactoryGirl.create(:project_permission) }
  let!(:auth_role) { FactoryGirl.create(:auth_role) }

  let(:resource_class) { ProjectPermission }
  let(:resource_serializer) { ProjectPermissionSerializer }
  let!(:resource) { project_permission }

  describe 'Project Permissions collection' do
    let(:url) { "/api/v1/projects/#{resource.project.id}/permissions" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a listable resource'

      it 'should only include permissions for this project' do
        expect(other_permission).to be_persisted
        get url, nil, headers
        expect(response.body).not_to include(resource_serializer.new(other_permission).to_json)
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/notexists_projectid/permissions" }
        let(:resource_class) {'Project'}
      end
    end
  end

  describe 'Project Permission instance' do
    let(:url) { "/api/v1/projects/#{resource.project.id}/permissions/#{resource.user.id}" }

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let!(:payload) {{
        auth_role: {id: auth_role.text_id}
      }}

      context 'non-existent project permission' do
        it 'should create a project permission' do
          expected_resource = resource.clone
          expected_resource.auth_role = auth_role
          resource.destroy
          expect(resource).not_to be_persisted
          expect {
            put url, payload.to_json, headers
            expect(response.status).to eq(200)
            expect(response.body).to be
            expect(response.body).not_to eq('null')
          }.to change{resource_class.count}.by(1)
          expect(response.body).to include(resource_serializer.new(expected_resource).to_json)
        end
      end

      it_behaves_like 'an updatable resource'
      it 'should update the auth_role' do
        expect {
          put url, payload.to_json, headers
          expect(response.status).to eq(200)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
        }.not_to change{resource_class.count}
        resource.reload
        expect(resource.auth_role).to eq(auth_role)
        expect(response.body).to include(resource_serializer.new(resource).to_json)
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/notexists_projectid/permissions/#{resource.user.id}" }
        let(:resource_class) {'Project'}
      end
      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/#{resource.project.id}/permissions/notexists_userid" }
        let(:resource_class) {'User'}
      end
      it_behaves_like 'an identified resource' do
        let!(:payload) {{
          auth_role: {id: 'invalid_role'}
        }}
        let(:resource_class) {'AuthRole'}
      end
    end

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/#{resource.project.id}/permissions/notexists_userid" }
        let(:resource_class) {'User'}
      end
      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/#{other_permission.project.id}/permissions/#{resource.user.id}" }
        let(:resource_class) {'ProjectPermission'}
      end
    end

    describe 'DELETE' do
      subject { delete(url, nil, headers) }
      it_behaves_like 'a removable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/#{resource.project.id}/permissions/notexists_userid" }
        let(:resource_class) {'User'}
      end
    end
  end
end
