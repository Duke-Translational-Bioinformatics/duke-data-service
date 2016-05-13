require 'rails_helper'
RSpec.describe AssociatedWithSoftwareAgentProvRelationSerializer, type: :serializer do
  let(:software_agent) { FactoryGirl.create(:software_agent) }
  let(:resource) { FactoryGirl.create(:associated_with_software_agent_prov_relation, relatable_from: software_agent) }

  it_behaves_like 'a ProvRelationSerializer', from: SoftwareAgentSerializer, to: ActivitySerializer
end
