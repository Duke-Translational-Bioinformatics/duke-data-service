require 'rails_helper'

RSpec.describe DataFileSerializer, type: :serializer do
  let(:resource) { child_file }
  let(:root_file) { FactoryGirl.create(:data_file, :root) }
  let(:child_file) { FactoryGirl.create(:data_file, :with_parent) }

  it 'should have one upload preview' do
    expect(described_class._associations).to have_key(:upload)
    expect(described_class._associations[:upload]).to be_a(ActiveModel::Serializer::Association::HasOne)
    expect(described_class._associations[:upload].serializer_from_options).to eq(UploadPreviewSerializer)
  end

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('parent')
      is_expected.to have_key('name')
      is_expected.to have_key('project')
      is_expected.to have_key('ancestors')
      is_expected.to have_key('is_deleted')
      expect(subject['id']).to eq(resource.id)
      expect(subject['parent']['id']).to eq(resource.parent_id)
      expect(subject['name']).to eq(resource.name)
      expect(subject['project']['id']).to eq(resource.project_id)
      expect(subject['is_deleted']).to eq(resource.is_deleted)
    end

    describe 'ancestors' do
      context 'with a parent folder' do
        let(:resource) { child_file }
        it 'should return the project and parent' do
          expect(resource.project).to be
          expect(resource.parent).to be
          expect(subject['ancestors']).to eq [
            {
              'kind' => resource.project.kind,
              'id' => resource.project.id,
              'name' => resource.project.name
            },
            {
              'kind' => resource.parent.kind,
              'id' => resource.parent.id,
              'name' => resource.parent.name
            }
          ]
        end
      end

      context 'without a parent' do
        let(:resource) { root_file }
        it 'should return the project' do
          expect(resource.project).to be
          expect(subject['ancestors']).to eq [
            {
              'kind' => resource.project.kind,
              'id' => resource.project.id,
              'name' => resource.project.name }
          ]
        end
      end
    end
  end
end
