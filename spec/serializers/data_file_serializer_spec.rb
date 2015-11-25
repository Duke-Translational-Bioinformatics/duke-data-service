require 'rails_helper'

RSpec.describe DataFileSerializer, type: :serializer do
  let(:resource) { child_file }
  let(:serializer) { DataFileSerializer.new(resource) }
  subject { JSON.parse(serializer.to_json) }

  let(:root_file) { FactoryGirl.create(:data_file, :root) }
  let(:child_file) { FactoryGirl.create(:data_file, :with_parent) }

  it 'should serialize to json' do
    expect{subject}.to_not raise_error
  end

  it 'should have expected keys and values' do
    is_expected.to have_key('id')
    is_expected.to have_key('parent')
    is_expected.to have_key('name')
    is_expected.to have_key('project')
    is_expected.to have_key('ancestors')
    is_expected.to have_key('is_deleted')
    is_expected.to have_key('upload')
    expect(subject['id']).to eq(resource.id)
    expect(subject['parent']['id']).to eq(resource.parent_id)
    expect(subject['name']).to eq(resource.name)
    expect(subject['project']['id']).to eq(resource.project_id)
    expect(subject['is_deleted']).to eq(resource.is_deleted)
    expect(subject['upload']['id']).to eq(resource.upload_id)
  end

  it 'should have upload in paylod' do
    is_expected.to have_key('upload')
    expect(resource.upload).not_to be_nil
    expect(subject['upload']).to eq({
      'id' => resource.upload.id,
      'size' => resource.upload.size,
      'hash' => {
        'value' => resource.upload.fingerprint_value,
        'algorithm' => resource.upload.fingerprint_algorithm
      },
      'storage_provider' => {
        'id' => resource.upload.storage_provider.id,
        'name' => resource.upload.storage_provider.display_name,
        'description' => resource.upload.storage_provider.description
      }
    })
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
