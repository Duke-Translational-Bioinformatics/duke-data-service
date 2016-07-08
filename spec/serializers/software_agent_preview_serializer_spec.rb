require 'rails_helper'

RSpec.describe SoftwareAgentPreviewSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:software_agent) }

  it_behaves_like 'a json serializer' do
    let(:expected_hash) { {
      id: resource.id,
      name: resource.name
    }.stringify_keys }
    it { is_expected.to eq(expected_hash) }
  end
end
