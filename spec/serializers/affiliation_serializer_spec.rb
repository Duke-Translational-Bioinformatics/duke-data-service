require 'rails_helper'

RSpec.describe AffiliationSerializer, type: :serializer do
  let(:resource) { FactoryGirl.build(:affiliation) }

  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer
  it_behaves_like 'a has_one association with', :project_role, ProjectRolePreviewSerializer

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key 'user'
      expect(subject['user']).to eq({
        'id' => resource.user.id,
        'full_name' => resource.user.display_name,
        'email' => resource.user.email
      })
    end
  end
end
