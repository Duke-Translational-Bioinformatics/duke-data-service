require 'rails_helper'

RSpec.describe SoftwareAgentSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:software_agent) }
  let(:is_logically_deleted) { true }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'description' => resource.description,
    'repo_url' => resource.repo_url,
    'is_deleted' => resource.is_deleted,
    'audit' => Hash
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
    it_behaves_like 'a serializer with a serialized audit'
  end
end
