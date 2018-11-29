require 'rails_helper'
RSpec.describe UsedProvRelationSerializer, type: :serializer do
  include_context 'mock all Uploads StorageProvider'
  let(:resource) { FactoryBot.create(:used_prov_relation) }

  it_behaves_like 'a ProvRelationSerializer', from: ActivitySerializer, to: FileVersionSerializer
end
