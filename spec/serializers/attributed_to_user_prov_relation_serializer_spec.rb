require 'rails_helper'
RSpec.describe AttributedToUserProvRelationSerializer, type: :serializer do
  include_context 'mock all Uploads StorageProvider'
  let(:resource) { FactoryBot.create(:attributed_to_user_prov_relation) }
  it_behaves_like 'a ProvRelationSerializer', from: FileVersionSerializer, to: UserSerializer
end
