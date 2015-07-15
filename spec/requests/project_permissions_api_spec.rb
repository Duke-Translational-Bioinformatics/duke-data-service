require 'rails_helper'

describe DDS::V1::ProjectPermissionsAPI do
  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:other_permission) { FactoryGirl.create(:project_permission) }
  let(:resource_class) { ProjectPermission }
  let(:resource_serializer) { ProjectPermissionSerializer }

  describe 'List project level permissions' do
    let!(:resource) { project_permission }
    let(:url) { "/api/v1/projects/#{resource.project.uuid}/permissions" }
    include_context 'with authentication'
    
    it_behaves_like 'a listable resource'

    it 'should only include permissions for this project' do
      expect(other_permission).to be_persisted
      get url, nil, headers
      expect(response.body).not_to include(resource_serializer.new(other_permission).to_json)
    end

    it_behaves_like 'a failed GET request' do
      include_context 'without authentication'
    end
  end
end
