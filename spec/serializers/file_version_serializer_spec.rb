require 'rails_helper'

RSpec.describe FileVersionSerializer, type: :serializer do
  include_context 'mock all Uploads StorageProvider'
  let(:resource) { FactoryBot.create(:file_version) }
  let(:is_logically_deleted) { true }
  let(:expected_attributes) {{
    'id' => resource.id,
    'version' => resource.version_number,
    'label' => resource.label,
    'is_deleted' => resource.is_deleted
  }}

  it_behaves_like 'a has_one association with', :data_file, DataFilePreviewSerializer, root: :file
  it_behaves_like 'a has_one association with', :upload, UploadPreviewSerializer

  it_behaves_like 'a json serializer' do
    it_behaves_like 'a serializer with a serialized audit'
    it { is_expected.to include(expected_attributes) }
  end
end
