require 'rails_helper'

RSpec.describe ChunkPreviewSerializer, type: :serializer do
  let(:resource) { FactoryBot.create(:chunk) }
  let(:expected_attributes) {{
    'number' => resource.number,
    'size' => resource.size,
    'hash' => { 'value' => resource.fingerprint_value,
                'algorithm' => resource.fingerprint_algorithm }
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
