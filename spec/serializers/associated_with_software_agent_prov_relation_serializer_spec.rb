require 'rails_helper'
RSpec.describe AssociatedWithSoftwareAgentProvRelationSerializer, type: :serializer do
  let(:software_agent) { FactoryBot.create(:software_agent) }
  let(:resource) { FactoryBot.create(:associated_with_software_agent_prov_relation, relatable_from: software_agent) }

  it_behaves_like 'a ProvRelationSerializer', from: SoftwareAgentSerializer, to: ActivitySerializer
end
