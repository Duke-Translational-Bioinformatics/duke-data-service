require 'rails_helper'
require 'jwt'

RSpec.describe User, type: :model do
  let(:user_authentication_service) { FactoryGirl.create(:user_authentication_service, :populated) }
  subject { user_authentication_service.user }
  let(:is_logically_deleted) { false }

  it_behaves_like 'an audited model' do
    it_behaves_like 'with a serialized audit'
  end

  it 'should have an audited_user_info method to return the information required by audit _by methods' do
    should respond_to('audited_user_info')
    audited_user_info = subject.audited_user_info
    expect(audited_user_info).to be
    expect(audited_user_info).to have_key(:id)
    expect(audited_user_info).to have_key(:username)
    expect(audited_user_info).to have_key(:full_name)
    expect(audited_user_info[:id]).to eq(subject.id)
    expect(audited_user_info[:username]).to eq(subject.username)
    expect(audited_user_info[:full_name]).to eq(subject.display_name)
  end

  describe 'associations' do
    subject {FactoryGirl.create(:user)}

    it 'should have_many user_authentication_services' do
      should have_many :user_authentication_services
    end

    it 'should have many affiliations' do
      should have_many(:affiliations)
    end

    it 'should have many created_files' do
      should have_many(:created_files).class_name('DataFile').with_foreign_key(:creator_id).conditions(is_deleted: false)
    end

    it 'should have many uploads through created_files' do
      should have_many(:uploads).through(:created_files)
    end

    it 'should have one system_permission' do
      should have_one(:system_permission)
    end
  end

  describe 'validations' do
    subject {FactoryGirl.create(:user)}

    it 'should validate presence of username' do
      should validate_presence_of(:username)
      should validate_uniqueness_of(:username)
    end
  end

  describe 'usage' do
    subject { FactoryGirl.create(:user) }
    let(:projects) { FactoryGirl.create_list(:project, 5, creator_id: subject.id) }
    let(:uploads) {
      uploads = []
      projects.each do |project|
        uploads << FactoryGirl.create(:upload, :completed, project_id: project.id)
      end
      uploads
    }
    let!(:files) {
      files = []
      uploads.each do |upload|
        files << FactoryGirl.create(:data_file, creator_id: subject.id, project_id: upload.project.id, upload_id: upload.id)
      end
      files
    }
    let!(:deleted_project) { FactoryGirl.create(:project, :deleted, creator_id: subject.id) }
    let(:deleted_upload) { FactoryGirl.create(:upload, :completed, project_id: projects.first.id)}
    let!(:deleted_file) { FactoryGirl.create(:data_file, :deleted, creator_id: subject.id, project_id: deleted_upload.project.id, upload_id: deleted_upload.id) }

    describe 'project_count' do
      let(:expected_count) { projects.count }

      it 'should provide the count of user projects' do
        expect(subject).to respond_to('project_count')
        expect(expected_count).to be > 0
        expect(subject.project_count).to eq(expected_count)
      end
    end

    describe 'file_count' do
      let(:expected_count) { files.count }
      it 'should provide the count of user files' do
        expect(subject).to respond_to('file_count')
        expect(expected_count).to be > 0
        expect(subject.file_count).to eq(expected_count)
      end
    end

    describe 'storage_bytes' do
      let(:expected_size) {
        expected_size = 0
        uploads.each do |f|
          expected_size = f.size + expected_size
        end
        expected_size
      }
      it 'should provide the sum total of the size of all user uploads' do
        expect(subject).to respond_to('storage_bytes')
        expect(expected_size).to be > 0
        expect(subject.storage_bytes).to eq(expected_size)
      end
    end
  end
end
