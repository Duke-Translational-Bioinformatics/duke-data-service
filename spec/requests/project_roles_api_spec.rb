require 'rails_helper'

describe DDS::V1::ProjectRolesAPI do
  include_context 'with authentication'

  let(:project_role) { FactoryGirl.create(:project_role) }
  let(:resource) { project_role }
  let(:resource_class) { ProjectRole }
  let(:resource_serializer) { ProjectRoleSerializer }

  describe 'List project roles' do
    let(:url) {"/api/v1/project_roles"}
    subject { get(url, headers: headers) }

    it_behaves_like 'a listable resource' do
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
  end

  describe 'View authorization role details' do
    let(:url) {"/api/v1/project_roles/#{resource_id}"}
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
