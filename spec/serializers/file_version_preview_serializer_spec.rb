require 'rails_helper'

RSpec.describe FileVersionPreviewSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:file_version) }
  let(:is_logically_deleted) { true }

  it_behaves_like 'a has_one association with', :upload, UploadPreviewSerializer

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('version')
      is_expected.to have_key('label')
      expect(subject['id']).to eq(resource.id)
      expect(subject['version']).to eq(resource.version_number)
      expect(subject['label']).to eq(resource.label)
    end
    it { is_expected.not_to have_key('kind') }
    it { is_expected.not_to have_key('is_deleted') }
    it { is_expected.not_to have_key('audit') }
    it { is_expected.not_to have_key('data_file') }
  end
end
