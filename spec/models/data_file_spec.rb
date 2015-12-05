require 'rails_helper'

RSpec.describe DataFile, type: :model do
  subject { child_file }
  let(:is_logically_deleted) { true }
  let(:root_file) { FactoryGirl.create(:data_file, :root) }
  let(:child_file) { FactoryGirl.create(:data_file, :with_parent) }
  let(:project) { subject.project }
  let(:other_project) { FactoryGirl.create(:project) }
  let(:other_folder) { FactoryGirl.create(:folder, project: other_project) }

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

    it 'should belong to creator' do
      should belong_to(:creator).class_name('User')
    end
  end

  describe 'validations' do
    let(:completed_upload) { FactoryGirl.create(:upload, :completed, creator: subject.creator, project: subject.project) }
    let(:incomplete_upload) { FactoryGirl.create(:upload, creator: subject.creator, project: subject.project) }
    let(:upload_with_error) { FactoryGirl.create(:upload, :with_error, creator: subject.creator, project: subject.project) }
    let(:not_creator_of_upload) { FactoryGirl.create(:upload, :completed, project: subject.project) }
    it 'should have a name' do
      should validate_presence_of(:name)
    end

    it 'should have a project_id' do
      should validate_presence_of(:project_id)
    end

    it 'should not allow project_id to be changed' do
      should allow_value(project).for(:project)
      expect(subject).to be_valid
      should allow_value(project.id).for(:project_id)
      should_not allow_value(other_project.id).for(:project_id)
      should allow_value(project.id).for(:project_id)
      expect(subject).to be_valid
      should allow_value(other_project).for(:project)
      expect(subject).not_to be_valid
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

    it 'should require creator equal upload.creator' do
      should allow_value(completed_upload.id).for(:upload_id)
      should_not allow_value(not_creator_of_upload.id).for(:upload_id)
      should allow_value(completed_upload).for(:upload)
      should_not allow_value(not_creator_of_upload).for(:upload)
      expect(subject.valid?).to be_falsey
      expect(subject.errors.keys).to include(:upload)
      expect(subject.errors[:upload]).to include('created by another user')
    end

    it 'should require a creator_id' do
      should validate_presence_of :creator_id
    end
  end

  describe '.parent=' do
    it 'should set project to parent.project' do
      expect(subject.parent).not_to eq other_folder
      expect(subject.project).not_to eq other_folder.project
      expect(subject.project_id).not_to eq other_folder.project_id
      should allow_value(other_folder).for(:parent)
      expect(subject.parent).to eq other_folder
      expect(subject.project).to eq other_folder.project
      expect(subject.project_id).to eq other_folder.project_id
    end
  end

  describe '.parent_id=' do
    it 'should set project to parent.project' do
      expect(subject.parent).not_to eq other_folder
      expect(subject.project).not_to eq other_folder.project
      expect(subject.project_id).not_to eq other_folder.project_id
      should allow_value(other_folder.id).for(:parent_id)
      expect(subject.parent).to eq other_folder
      expect(subject.project).to eq other_folder.project
      expect(subject.project_id).to eq other_folder.project_id
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
