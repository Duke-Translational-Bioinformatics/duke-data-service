require 'rails_helper'
RSpec.describe AttributedToSoftwareAgentProvRelationSerializer, type: :serializer do
  include_context 'mock all Uploads StorageProvider'
  let(:software_agent) { FactoryBot.create(:software_agent) }
  let(:resource) { FactoryBot.create(:attributed_to_software_agent_prov_relation,
    relatable_to: software_agent) }
  it_behaves_like 'a ProvRelationSerializer', from: FileVersionSerializer, to: SoftwareAgentSerializer
end
