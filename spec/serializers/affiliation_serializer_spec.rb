require 'rails_helper'

RSpec.describe AffiliationSerializer, type: :serializer do
  let(:resource) { FactoryGirl.build(:affiliation) }
  let(:expected_attributes) {{
    'user' => { 'id' => resource.user.id,
                'full_name' => resource.user.display_name,
                'email' => resource.user.email
              }
  }}

  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer
  it_behaves_like 'a has_one association with', :project_role, ProjectRolePreviewSerializer

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
