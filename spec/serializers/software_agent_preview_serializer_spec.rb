require 'rails_helper'

RSpec.describe SoftwareAgentPreviewSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:software_agent) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name
  }}
  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
