require 'rails_helper'
RSpec.describe AttributedToUserProvRelationSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:attributed_to_user_prov_relation) }
  it_behaves_like 'a ProvRelationSerializer', from: FileVersionSerializer, to: UserSerializer
end
