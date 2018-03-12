require 'rails_helper'

RSpec.describe PropertyPreviewSerializer, type: :serializer do
  let(:resource) { FactoryBot.create(:property) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'key' => resource.key,
    'label' => resource.label
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
