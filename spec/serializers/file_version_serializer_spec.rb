require 'rails_helper'

RSpec.describe FileVersionSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:file_version) }
  let(:is_logically_deleted) { true }

  it_behaves_like 'a has_one association with', :data_file, DataFilePreviewSerializer, root: :file
  it_behaves_like 'a has_one association with', :upload, UploadPreviewSerializer

  it_behaves_like 'a json serializer' do
    it_behaves_like 'a serializer with a serialized audit'

    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('version')
      is_expected.to have_key('label')
      is_expected.to have_key('is_deleted')
      expect(subject['id']).to eq(resource.id)
      expect(subject['version']).to eq(resource.version_number)
      expect(subject['label']).to eq(resource.label)
      expect(subject['is_deleted']).to eq(resource.is_deleted)
    end
  end
end
