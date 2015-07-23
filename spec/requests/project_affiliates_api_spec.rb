require 'rails_helper'

describe DDS::V1::ProjectAffiliatesAPI do
  include_context 'with authentication'

  let(:membership) { FactoryGirl.create(:membership) }
  let(:project) { FactoryGirl.create(:project) }
  let(:user) { FactoryGirl.create(:user) }
  let(:serialized_membership) { MembershipSerializer.new(membership).to_json }

  let(:resource_class) { Membership }
  let(:resource_serializer) { MembershipSerializer }
  let!(:resource) { membership }

  describe 'Project Affiliate collection' do
    let(:url) { "/api/v1/project/#{project.id}/affiliates" }

    describe 'GET' do
      subject { get(url, nil, headers) }
      let(:project) { resource.project }

      it_behaves_like 'a listable resource'

      it_behaves_like 'an authenticated resource'
    end

    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
      let!(:payload) {{
        user: {
          id: resource.user.id
        },
        project_roles: [{id: 'principal_investigator'}]
      }}

      it_behaves_like 'a creatable resource'

      it_behaves_like 'a validated resource' do
        let(:payload) {{
          user: {
            id: nil
          },
          project_roles: [{id: 'principal_investigator'}]
        }}
        it 'should not persist changes' do
          expect(resource).to be_persisted
          expect {
            is_expected.to eq(400)
          }.not_to change{resource_class.count}
        end
      end

      it_behaves_like 'an authenticated resource'
    end
  end

  describe 'Project Affiliate instance' do
    let(:url) { "/api/v1/project_affiliates/#{resource.id}" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
    end

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let!(:payload) {{
        user: {id: user.id},
        project_roles: [{id: 'research_coordinator'}]
      }}
      it_behaves_like 'an updatable resource'
      it_behaves_like 'a validated resource' do
        let(:payload) {{
          user: {id: nil},
          project_roles: [{id: 'principal_investigator'}]
        }}
      end

      it_behaves_like 'an authenticated resource'
    end

    describe 'DELETE' do
      subject { delete(url, nil, headers) }
      it_behaves_like 'a removable resource'

      it_behaves_like 'an authenticated resource'
    end
  end
end
