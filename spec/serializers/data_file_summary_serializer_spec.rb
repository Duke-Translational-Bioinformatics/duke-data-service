require 'rails_helper'

RSpec.describe DataFileSummarySerializer, type: :serializer do
  include_context 'mock all Uploads StorageProvider'
  let(:resource) { FactoryBot.create(:data_file, :with_parent) }
  let(:is_logically_deleted) { true }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'ancestors' => expected_ancestors,
    'size' => resource.upload.size,
    'hashes' => expected_fingerprints,
    'file_url' => {
      'http_verb' => resource.http_verb,
      'host' => resource.host,
      'url' => resource.url,
      'http_headers' => []
    }
  }}
  let(:expected_ancestors) { resource.ancestors.collect {|a|
    {
      'kind' => a.kind,
      'id' => a.id,
      'name' => a.name,
    }
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
