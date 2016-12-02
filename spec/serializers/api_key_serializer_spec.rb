require 'rails_helper'

RSpec.describe ApiKeySerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:api_key) }
  let(:expected_attributes) {{
    'key' => resource.key
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
