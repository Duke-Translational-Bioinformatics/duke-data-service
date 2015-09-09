require 'rails_helper'

describe DDS::V1::ProjectRolesAPI do
  include_context 'with authentication'

  let(:project_role) { FactoryGirl.create(:project_role) }
  let(:resource) { project_role }
  let(:resource_class) { ProjectRole }
  let(:resource_serializer) { ProjectRoleSerializer }

  describe 'List project roles' do
    let(:url) {"/api/v1/project_roles"}
    subject { get(url, nil, headers) }

    it_behaves_like 'a listable resource'

    it_behaves_like 'an authenticated resource'
  end

  describe 'View authorization role details' do
    let(:url) {"/api/v1/project_roles/#{resource.id}"}
    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'

      it_behaves_like 'an identified resource' do
        let(:url) {"/api/v1/project_roles/notexists_projectrole_id"}
      end
    end
  end
end
