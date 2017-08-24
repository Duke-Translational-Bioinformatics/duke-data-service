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
    let(:expected_kind) { 'dds-file' }
    let(:kinded_class) { DataFile }
    let(:serialized_kind) { true }
  end
  it_behaves_like 'a logically deleted model'
  it_behaves_like 'a job_transactionable model'

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:parent) }
    it { is_expected.to have_many(:project_permissions).through(:project) }
    it { is_expected.to have_many(:file_versions).order('version_number ASC').autosave(true) }
    it { is_expected.to have_many(:tags) }
    it { is_expected.to have_many(:meta_templates) }
  end

  describe 'validations' do
    let(:completed_upload) { FactoryGirl.create(:upload, :completed, :with_fingerprint, project: subject.project) }
    let(:incomplete_upload) { FactoryGirl.create(:upload, project: subject.project) }
    let(:upload_with_error) { FactoryGirl.create(:upload, :with_error, project: subject.project) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:upload) }

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

    it 'should require upload has no error' do
      should allow_value(completed_upload).for(:upload)
      should_not allow_value(upload_with_error).for(:upload)
      should_not allow_value(upload_with_error).for(:upload)
      expect(subject.valid?).to be_falsey
      expect(subject.errors.keys).to include(:upload)
      expect(subject.errors[:upload]).to include('cannot have an error')
    end

    it 'should require a completed upload' do
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
      it { is_expected.not_to validate_presence_of(:upload) }
      it { expect(deleted_file.file_versions).to all( be_is_deleted ) }
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

    describe '#upload' do
      subject { FactoryGirl.build(:data_file, without_upload: true) }
      let(:completed_upload) { FactoryGirl.create(:upload, :completed, :with_fingerprint, project: subject.project) }
      let(:different_upload) { FactoryGirl.create(:upload, :completed, :with_fingerprint, project: subject.project) }

      context 'before save' do
        it { expect(subject.upload).to be_nil }
        it { expect(subject.file_versions).to be_empty }

        context 'set #upload to nil' do
          before(:each) do
            expect {
              subject.upload = nil
            }.to change { subject.file_versions.length }.by(1)
          end

          it { expect(subject.upload).to be_nil }
          it { expect(subject.current_file_version.upload).to be_nil }
        end

        context 'set #upload to an upload' do
          before(:each) do
            expect {
              subject.upload = completed_upload
            }.to change { subject.file_versions.length }.by(1)
          end

          it { expect(subject.upload).to eq completed_upload }
          it { expect(subject.current_file_version.upload).to eq completed_upload }
        end
      end

      context 'after save' do
        before(:each) do
          subject.upload = completed_upload
          expect(subject.save).to be_truthy
        end
        it { expect(subject.upload).to eq completed_upload }
        it { expect(subject.file_versions.length).to eq(1) }
        it { expect(subject.current_file_version.upload).to eq completed_upload }

        context 'set #upload to nil' do
          before(:each) do
            expect {
              subject.upload = nil
            }.to change { subject.file_versions.length }.by(1)
          end

          it { expect(subject.upload).to be_nil }
          it { expect(subject.current_file_version.upload).to be_nil }
        end

        context 'set #upload to a different upload' do
          before(:each) do
            expect {
              subject.upload = different_upload
            }.to change { subject.file_versions.length }.by(1)
          end

          it { expect(subject.upload).to eq different_upload }
          it { expect(subject.current_file_version.upload).to eq different_upload }
        end

        context 'set #upload to the same upload' do
          before(:each) do
            expect {
              subject.upload = completed_upload
            }.not_to change { subject.file_versions.length }
          end

          it { expect(subject.upload).to eq completed_upload }
          it { expect(subject.current_file_version.upload).to eq completed_upload }
        end
      end
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

      context 'with multiple file_versions' do
        let(:last_file_version) { FactoryGirl.create(:file_version, data_file: subject) }
        before do
          expect(last_file_version).to be_persisted
          subject.reload
        end
        it { expect(subject.current_file_version).to eq last_file_version }
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
  end

  describe 'callbacks' do
    it { is_expected.to callback(:set_project_to_parent_project).after(:set_parent_attribute) }
    it { is_expected.to callback(:set_current_file_version_attributes).before(:save) }
  end

  describe '#creator' do
    let(:creator) { FactoryGirl.create(:user) }
    it { is_expected.to respond_to :creator }

    context 'with nil current_file_version' do
      subject {
        df = FactoryGirl.create(:data_file)
        df.file_versions.destroy_all
        df
      }
      it {
        expect(subject.current_file_version).to be_nil
        expect(subject.creator).to be_nil
      }
    end

    context 'with nil current_file_version create audit' do
      subject {
        FactoryGirl.create(:data_file)
      }

      around(:each) do |example|
          FileVersion.auditing_enabled = false
          example.run
          FileVersion.auditing_enabled = true
      end

      it {
        expect(subject.current_file_version).not_to be_nil
        expect(subject.current_file_version.audits.find_by(action: 'create')).to be_nil
        expect(subject.creator).to be_nil
      }
    end

    context 'with current_file_version and create audit' do
      subject {
        Audited.audit_class.as_user(creator) do
          FactoryGirl.create(:data_file)
        end
      }
      it {
        expect(subject.current_file_version).not_to be_nil
        expect(subject.current_file_version.audits.find_by(action: 'create')).not_to be_nil
        expect(subject.creator.id).to eq(subject.current_file_version.audits.find_by(action: 'create').user.id)
      }
    end
  end

  describe 'elasticsearch' do
    let(:search_serializer) { Search::DataFileSerializer }
    let(:property_mappings) {{
      kind: {type: "string"},
      name: {type: "string"}, #name
      tags: {type: "object"},
      project: {type: "object"}
    }}
    include_context 'with job runner', ElasticsearchIndexJob

    it_behaves_like 'a SearchableModel' do
      context 'when ElasticsearchIndexJob::perform_later raises an error' do
        context 'with new data_file' do
          subject { FactoryGirl.build(:data_file, :root) }
          before(:each) do
            expect(ElasticsearchIndexJob).to receive(:perform_later).with(anything, anything).and_raise("boom!")
          end
          it { expect{
            expect{subject.save}.to raise_error("boom!")
          }.not_to change{described_class.count} }
        end
        context 'with existing data_file' do
          subject { root_file }
          before(:each) do
            is_expected.to be_persisted
            subject.name += 'x'
            expect(ElasticsearchIndexJob).to receive(:perform_later).with(anything, anything, update: true).and_raise("boom!")
          end
          it { expect{
            expect{subject.save}.to raise_error("boom!")
          }.not_to change{described_class.find(subject.id).name} }
        end
      end
    end
    it_behaves_like 'an Elasticsearch index mapping model' do
      it {
        # kind.raw
        expect(subject[:data_file][:properties][:kind]).to have_key :fields
        expect(subject[:data_file][:properties][:kind][:fields]).to have_key :raw
        expect(subject[:data_file][:properties][:kind][:fields][:raw][:type]).to eq "string"
        expect(subject[:data_file][:properties][:kind][:fields][:raw][:index]).to eq "not_analyzed"

        #tags.label
        expect(subject[:data_file][:properties][:tags]).to have_key :properties
        expect(subject[:data_file][:properties][:tags][:properties]).to have_key :label
        expect(subject[:data_file][:properties][:tags][:properties][:label][:type]).to eq "string"

        #tags.label.raw
        expect(subject[:data_file][:properties][:tags][:properties][:label]).to have_key :fields
        expect(subject[:data_file][:properties][:tags][:properties][:label][:fields]).to have_key :raw
        expect(subject[:data_file][:properties][:tags][:properties][:label][:fields][:raw][:type]).to eq "string"
        expect(subject[:data_file][:properties][:tags][:properties][:label][:fields][:raw][:index]).to eq "not_analyzed"

        #project.id.raw
        expect(subject[:data_file][:properties][:project]).to have_key :properties
        expect(subject[:data_file][:properties][:project][:properties]).to have_key :id
        expect(subject[:data_file][:properties][:project][:properties][:id][:type]).to eq "string"
        expect(subject[:data_file][:properties][:project][:properties][:id]).to have_key :fields
        expect(subject[:data_file][:properties][:project][:properties][:id][:fields]).to have_key :raw
        expect(subject[:data_file][:properties][:project][:properties][:id][:fields][:raw][:type]).to eq "string"
        expect(subject[:data_file][:properties][:project][:properties][:id][:fields][:raw][:index]).to eq "not_analyzed"

        #project.name.raw
        expect(subject[:data_file][:properties][:project][:properties]).to have_key :name
        expect(subject[:data_file][:properties][:project][:properties][:name][:type]).to eq "string"
        expect(subject[:data_file][:properties][:project][:properties][:name]).to have_key :fields
        expect(subject[:data_file][:properties][:project][:properties][:name][:fields]).to have_key :raw
        expect(subject[:data_file][:properties][:project][:properties][:name][:fields][:raw][:type]).to eq "string"
        expect(subject[:data_file][:properties][:project][:properties][:name][:fields][:raw][:index]).to eq "not_analyzed"
      }
    end
  end
end
