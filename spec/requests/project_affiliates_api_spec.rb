require 'rails_helper'

describe DDS::V1::ProjectAffiliatesAPI do
  include_context 'with authentication'

  let(:affiliation) { FactoryGirl.create(:affiliation) }
  let(:project) { affiliation.project }
  let(:user) { affiliation.user }
  let(:project_role) { FactoryGirl.create(:project_role) }

  let(:resource_class) { Affiliation }
  let(:resource_serializer) { AffiliationSerializer }
  let!(:resource) { affiliation }

  describe 'Project Affiliate collection' do
    let(:url) { "/api/v1/projects/#{project.id}/affiliates" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a listable resource'

      it_behaves_like 'an authenticated resource'
    end
  end

  describe 'Project Affiliate instance' do
    let(:url) { "/api/v1/projects/#{project.id}/affiliates/#{user.id}" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      #it_behaves_like 'a viewable resource'

      #it_behaves_like 'an authenticated resource'
    end

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let!(:payload) {{
        project_role: {id: project_role.id}
      }}

      it_behaves_like 'a creatable resource' do
        let(:user) { FactoryGirl.create(:user) }
        let(:expected_response_status) {200}
        let(:new_object) { resource_class.last }
      end

      it_behaves_like 'an updatable resource'
      
      it_behaves_like 'a validated resource' do
        let(:payload) {{
          project_role: {id: nil}
        }}
      end

      it_behaves_like 'an authenticated resource'
    end

    describe 'DELETE' do
      subject { delete(url, nil, headers) }
      #it_behaves_like 'a removable resource'

      #it_behaves_like 'an authenticated resource'
    end
  end
end
