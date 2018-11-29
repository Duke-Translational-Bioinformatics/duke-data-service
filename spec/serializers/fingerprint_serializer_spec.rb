require 'rails_helper'

RSpec.describe FingerprintSerializer, type: :serializer do
  let(:resource) { FactoryBot.create(:fingerprint) }
  let(:is_logically_deleted) { false }
  let(:expected_attributes) {{
    'algorithm' => resource.algorithm,
    'value' => resource.value
  }}

  include_context 'mock all Uploads StorageProvider'

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
    it_behaves_like 'a serializer with a serialized audit'
  end
end
