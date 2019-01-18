require 'rails_helper'

RSpec.describe FileVersionPreviewSerializer, type: :serializer do
  include_context 'mock all Uploads StorageProvider'
  let(:resource) { FactoryBot.create(:file_version) }
  let(:is_logically_deleted) { true }
  let(:expected_attributes) {{
    'id' => resource.id,
    'version' => resource.version_number,
    'label' => resource.label
  }}

  it_behaves_like 'a has_one association with', :upload, UploadPreviewSerializer

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
    it { is_expected.not_to have_key('kind') }
    it { is_expected.not_to have_key('is_deleted') }
    it { is_expected.not_to have_key('audit') }
    it { is_expected.not_to have_key('data_file') }
  end
end
