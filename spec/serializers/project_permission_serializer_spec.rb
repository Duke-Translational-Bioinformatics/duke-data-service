require 'rails_helper'

RSpec.describe ProjectPermissionSerializer, type: :serializer do
  let(:resource) { FactoryBot.build(:project_permission) }

  it_behaves_like 'a has_one association with', :user, UserPreviewSerializer
  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer
  it_behaves_like 'a has_one association with', :auth_role, AuthRolePreviewSerializer

  it_behaves_like 'a json serializer'
end
