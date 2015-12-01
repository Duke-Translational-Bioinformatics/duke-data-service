require 'rails_helper'

RSpec.describe DataFileSerializer, type: :serializer do
  let(:resource) { child_file }
  let(:root_file) { FactoryGirl.create(:data_file, :root) }
  let(:child_file) { FactoryGirl.create(:data_file, :with_parent) }

  it_behaves_like 'a has_one association with', :upload, UploadPreviewSerializer
  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer
  it_behaves_like 'a has_many association with', :ancestors, AncestorSerializer

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('parent')
      is_expected.to have_key('name')
      is_expected.to have_key('is_deleted')
      expect(subject['id']).to eq(resource.id)
      expect(subject['parent']['id']).to eq(resource.parent_id)
      expect(subject['name']).to eq(resource.name)
      expect(subject['is_deleted']).to eq(resource.is_deleted)
    end
  end
end
