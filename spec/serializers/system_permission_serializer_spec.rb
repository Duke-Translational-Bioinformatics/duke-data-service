require 'rails_helper'

RSpec.describe SystemPermissionSerializer, type: :serializer do
  let(:resource) { FactoryGirl.build(:system_permission) }

  it_behaves_like 'a has_one association with', :user, UserPreviewSerializer
  it_behaves_like 'a has_one association with', :auth_role, AuthRolePreviewSerializer

  it_behaves_like 'a json serializer'
end
