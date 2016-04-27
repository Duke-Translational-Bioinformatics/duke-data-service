require 'rails_helper'

RSpec.describe DataFile, type: :model do
  subject { child_file }
  let(:root_file) { FactoryGirl.create(:data_file, :root) }
  let(:child_file) { FactoryGirl.create(:data_file, :with_parent) }
  let(:invalid_file) { FactoryGirl.create(:data_file, :invalid) }
  let(:deleted_file) { FactoryGirl.create(:data_file, :deleted) }
  let(:project) { subject.project }
  let(:other_project) { FactoryGirl.create(:project) }
  let(:other_folder) { FactoryGirl.create(:folder, project: other_project) }
  let(:uri_encoded_name) { URI.encode(subject.name) }

  it_behaves_like 'an audited model'
  it_behaves_like 'a kind' do
    let!(:kind_name) { 'file' }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:parent) }
    it { is_expected.to belong_to(:upload) }
    it { is_expected.to have_many(:project_permissions).through(:project) }
    it { is_expected.to have_many(:file_versions).order('version_number DESC') }
  end

  describe 'validations' do
    let(:completed_upload) { FactoryGirl.create(:upload, :completed, project: subject.project) }
    let(:incomplete_upload) { FactoryGirl.create(:upload, project: subject.project) }
    let(:upload_with_error) { FactoryGirl.create(:upload, :with_error, project: subject.project) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:project_id) }

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

    it 'should allow is_deleted to be set' do
      should allow_value(true).for(:is_deleted)
      should allow_value(false).for(:is_deleted)
    end

    context 'when .is_deleted=true' do
      subject { deleted_file }
      it { is_expected.not_to validate_presence_of(:name) }
      it { is_expected.not_to validate_presence_of(:project_id) }
      it { is_expected.not_to validate_presence_of(:upload_id) }
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
    it { should delegate_method(:http_verb).to(:upload) }
    it { should delegate_method(:host).to(:upload).as(:url_root) }
    it { should delegate_method(:url).to(:upload).as(:temporary_url) }

    describe '#url' do
      it { expect(subject.url).to include uri_encoded_name }
    end

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

    describe '#current_file_version' do
      it { is_expected.to respond_to(:current_file_version) }
      it { expect(subject.current_file_version).to be_persisted }
      it { expect(subject.current_file_version).to eq subject.current_file_version }

      context 'with unsaved file_version' do
        before { subject.build_file_version }
        it { expect(subject.current_file_version).not_to be_persisted }
        it { expect(subject.current_file_version).to eq subject.current_file_version }
      end
    end

    describe '#build_file_version' do
      it { is_expected.to respond_to(:build_file_version) }
      it { expect(subject.build_file_version).to be_a FileVersion }
      it 'builds a file_version' do
        expect { 
          subject.build_file_version
        }.to change{subject.file_versions.length}.by(1)
      end
    end

    describe '#set_current_file_version_attributes' do
      let(:latest_version) { subject.current_file_version }
      it { is_expected.to respond_to(:set_current_file_version_attributes) }
      it { expect(subject.set_current_file_version_attributes).to be_a FileVersion }
      it { expect(subject.set_current_file_version_attributes).to eq latest_version }
      context 'with persisted file_version' do
        it { expect(latest_version).to be_persisted }
        it { expect(subject.set_current_file_version_attributes.changed?).to be_falsey }
      end
      context 'with new file_version' do
        before { subject.build_file_version }
        it { expect(subject.set_current_file_version_attributes.changed?).to be_truthy }
        it { expect(subject.set_current_file_version_attributes.upload).to eq subject.upload }
        it { expect(subject.set_current_file_version_attributes.label).to eq subject.label }
      end
    end

    describe '#new_file_version_needed?' do
      it { is_expected.to respond_to(:new_file_version_needed?) }
      it { expect(subject.upload_id_changed?).to be_falsey }
      it { expect(subject.new_file_version_needed?).to be_falsey }

      context 'when upload changed' do
        let!(:original_upload) { subject.upload }
        let(:new_upload) { FactoryGirl.create(:upload, :completed) }
        before { subject.upload = new_upload }
        it { expect(subject.current_file_version).to be_persisted }
        it { expect(subject.upload_id_changed?).to be_truthy }
        it { expect(subject.new_file_version_needed?).to be_truthy }

        context 'after call to build_file_version' do
          before { subject.build_file_version }
          it { expect(subject.current_file_version).not_to be_persisted }
          it { expect(subject.upload_id_changed?).to be_truthy }
          it { expect(subject.new_file_version_needed?).to be_falsey }
        end
      end

      context 'when current_file_version.upload differs' do
        let(:different_upload) { FactoryGirl.create(:upload, :completed) }
        before do 
          subject.current_file_version.update_attribute(:upload, different_upload) 
          subject.reload
        end
        it { expect(subject.current_file_version).to be_persisted }
        it { expect(subject.current_file_version.upload).not_to eq subject.upload }
        it { expect(subject.new_file_version_needed?).to be_truthy }
      end

      context 'before subject is created' do
        subject { FactoryGirl.build(:data_file) }
        
        it { is_expected.not_to be_persisted }
        context 'without file_versions' do
          it { expect(subject.file_versions).to be_empty }
          it { expect(subject.new_file_version_needed?).to be_truthy }
        end
        context 'with a file_version' do
          before { subject.build_file_version }
          it { expect(subject.file_versions).not_to be_empty }
          it { expect(subject.new_file_version_needed?).to be_falsey }
        end
      end
    end
  end

  describe 'callbacks' do
    it { is_expected.to callback(:set_project_to_parent_project).after(:set_parent_attribute) }
    it { is_expected.to callback(:build_file_version).before(:save).if(:new_file_version_needed?) }
    it { is_expected.to callback(:set_current_file_version_attributes).before(:save) }
  end
end
