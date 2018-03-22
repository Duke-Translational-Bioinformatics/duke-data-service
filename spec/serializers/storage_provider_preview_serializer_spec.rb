require 'rails_helper'

RSpec.describe StorageProviderPreviewSerializer, type: :serializer do
  let(:resource) { FactoryBot.create(:storage_provider) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.display_name,
    'description' => resource.description
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
