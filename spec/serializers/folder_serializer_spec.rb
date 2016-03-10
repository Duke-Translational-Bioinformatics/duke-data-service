require 'rails_helper'

RSpec.describe FolderSerializer, type: :serializer do
  let(:resource) { child_folder }
  let(:child_folder) { FactoryGirl.create(:folder, :with_parent) }
  let(:root_folder) { FactoryGirl.create(:folder, :root) }

  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer
  it_behaves_like 'a has_many association with', :ancestors, AncestorSerializer

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('parent')
      expect(subject['parent']).to have_key('kind')
      expect(subject['parent']).to have_key('id')
      is_expected.to have_key('name')
      is_expected.to have_key('is_deleted')

      expect(subject['id']).to eq(resource.id)
      expect(subject['parent']['kind']).to eq(resource.parent.kind)
      expect(subject['parent']['id']).to eq(resource.parent.id)
      expect(subject['name']).to eq(resource.name)
      expect(subject['is_deleted']).to eq(resource.is_deleted)
    end

    context 'without a parent' do
      let(:resource) { root_folder }

      it 'should have expected keys and values' do
        is_expected.to have_key('parent')
        expect(subject['parent']).to have_key('kind')
        expect(subject['parent']).to have_key('id')

        expect(subject['parent']['kind']).to eq(resource.project.kind)
        expect(subject['parent']['id']).to eq(resource.project.id)
      end
    end
  end
end
