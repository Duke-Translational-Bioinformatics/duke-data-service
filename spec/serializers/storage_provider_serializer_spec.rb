require 'rails_helper'

RSpec.describe StorageProviderSerializer, type: :serializer do
  let(:resource) { FactoryBot.create(:storage_provider) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.display_name,
    'description' => resource.description,
    'is_deprecated' => resource.is_deprecated,
    'is_default' => resource.is_default,
    'chunk_hash_algorithm' => resource.chunk_hash_algorithm,
    'chunk_max_number' => resource.chunk_max_number,
    'chunk_max_size_bytes' => resource.chunk_max_size_bytes
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
