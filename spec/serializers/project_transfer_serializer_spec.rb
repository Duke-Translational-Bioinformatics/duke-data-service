require 'rails_helper'

RSpec.describe ProjectTransferSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:project_transfer, :with_to_users, status: :pending) }
  let(:is_logically_deleted) { false }
  let(:expected_attributes) {{
    'id' => resource.id,
    'status' => resource.status,
    'status_comment' => resource.status_comment
  }}

  it_behaves_like 'a has_many association with', :to_users, UserPreviewSerializer
  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer
  it_behaves_like 'a has_one association with', :from_user, UserPreviewSerializer

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
    it_behaves_like 'a serializer with a serialized audit'
  end
end
