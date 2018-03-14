require 'rails_helper'
RSpec.describe AssociatedWithUserProvRelationSerializer, type: :serializer do
  let(:resource) { FactoryBot.create(:associated_with_user_prov_relation) }
  it_behaves_like 'a ProvRelationSerializer', from: UserSerializer, to: ActivitySerializer
end
