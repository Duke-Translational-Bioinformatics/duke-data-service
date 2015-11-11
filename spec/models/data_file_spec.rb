require 'rails_helper'

RSpec.describe DataFile, type: :model do
  subject { child_file }
  let(:resource_class) { DataFile }
  let(:resource_serializer) { DataFileSerializer }
  let!(:resource) { subject }
  let(:is_logically_deleted) { true }
  let(:root_file) { FactoryGirl.create(:data_file, :root) }
  let(:child_file) { FactoryGirl.create(:data_file, :with_parent) }

  it_behaves_like 'an audited model' do
    it_behaves_like 'with a serialized audit'
  end

  it_behaves_like 'a kind' do
    let!(:kind_name) { 'file' }
  end

  describe 'associations' do
    it 'should be part of a project' do
      should belong_to(:project)
    end

    it 'should have a parent' do
      should belong_to(:parent)
    end

    it 'should be based on an upload' do
      should belong_to(:upload)
    end

    it 'should have many project permissions' do
      should have_many(:project_permissions).through(:project)
    end
  end

  describe 'validations' do
    let(:completed_upload) { FactoryGirl.create(:upload, :completed, project: subject.project) }
    let(:incomplete_upload) { FactoryGirl.create(:upload, project: subject.project) }
    let(:upload_with_error) { FactoryGirl.create(:upload, :with_error, project: subject.project) }
    it 'should have a name' do
      should validate_presence_of(:name)
    end

    it 'should have a project_id' do
      should validate_presence_of(:project_id)
    end

    it 'should have a upload_id' do
      should validate_presence_of(:upload_id)
    end

    it 'should require upload has no error' do
      should allow_value(completed_upload.id).for(:upload_id)
      should_not allow_value(upload_with_error.id).for(:upload_id)
      should allow_value(completed_upload).for(:upload)
      should_not allow_value(upload_with_error).for(:upload)
      should_not allow_value(upload_with_error).for(:upload)
      expect(subject.valid?).to be_falsey
      expect(subject.errors.keys).to include(:upload)
      expect(subject.errors[:upload]).to include('cannot have an error')
    end

    it 'should require a completed upload' do
      should allow_value(completed_upload.id).for(:upload_id)
      should_not allow_value(incomplete_upload.id).for(:upload_id)
      should allow_value(completed_upload).for(:upload)
      should_not allow_value(incomplete_upload).for(:upload)
      expect(subject.valid?).to be_falsey
      expect(subject.errors.keys).to include(:upload)
      expect(subject.errors[:upload]).to include('must be completed successfully')
    end
  end

  describe 'serialization' do
    let(:serializer) { DataFileSerializer.new subject }
    let(:payload) { serializer.to_json }
    let(:parsed_json) { JSON.parse(payload) }
    it 'should serialize to json' do
      expect(payload).to be
      expect{parsed_json}.to_not raise_error
    end

    it 'should expected keys and values' do
      expect(parsed_json).to have_key('id')
      expect(parsed_json).to have_key('parent')
      expect(parsed_json).to have_key('name')
      expect(parsed_json).to have_key('project')
      expect(parsed_json).to have_key('ancestors')
      expect(parsed_json).to have_key('is_deleted')
      expect(parsed_json).to have_key('upload')
      expect(parsed_json['id']).to eq(subject.id)
      expect(parsed_json['parent']['id']).to eq(subject.parent_id)
      expect(parsed_json['name']).to eq(subject.name)
      expect(parsed_json['project']['id']).to eq(subject.project_id)
      expect(parsed_json['is_deleted']).to eq(subject.is_deleted)
      expect(parsed_json['upload']['id']).to eq(subject.upload_id)
    end

    describe 'ancestors' do
      context 'with a parent folder' do
        subject { child_file }
        it 'should return the project and parent' do
          expect(subject.project).to be
          expect(subject.parent).to be
          expect(parsed_json['ancestors']).to eq [
            {
              'kind' => subject.project.kind,
              'id' => subject.project.id,
              'name' => subject.project.name
            },
            {
              'kind' => subject.parent.kind,
              'id' => subject.parent.id,
              'name' => subject.parent.name
            }
          ]
        end
      end

      context 'without a parent' do
        subject { root_file }
        it 'should return the project' do
          expect(subject.project).to be
          expect(parsed_json['ancestors']).to eq [
            {
              'kind' => subject.project.kind,
              'id' => subject.project.id,
              'name' => subject.project.name }
          ]
        end
      end
    end
  end

  describe 'instance methods' do
    describe 'ancestors' do
      it 'should respond with an Array' do
        is_expected.to respond_to(:ancestors)
        expect(subject.ancestors).to be_a Array
      end

      context 'with a parent folder' do
        subject { child_file }
        it 'should return the project and parent' do
          expect(subject.project).to be
          expect(subject.parent).to be
          expect(subject.ancestors).to eq [subject.project, subject.parent]
        end
      end

      context 'without a parent' do
        subject { root_file }
        it 'should return the project' do
          expect(subject.project).to be
          expect(subject.ancestors).to eq [subject.project]
        end
      end
    end
  end
end
