require 'rails_helper'
require 'jwt'

RSpec.describe User, type: :model do
  let(:user_authentication_service) { FactoryGirl.create(:user_authentication_service, :populated) }
  subject { user_authentication_service.user }

  it_behaves_like 'an audited model'
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

  context 'current_software_agent attribute' do
    let (:software_agent) {
      FactoryGirl.create(:software_agent, :with_key, creator: subject)
    }

    it 'should be an accessor' do
      should respond_to('current_software_agent')
      subject.current_software_agent = software_agent
      expect(subject.current_software_agent.id).to eq(software_agent.id)
    end
  end

  describe 'associations' do
    subject {FactoryGirl.create(:user)}

    it 'should have_many user_authentication_services' do
      should have_many :user_authentication_services
    end

    it 'should have many affiliations' do
      should have_many(:affiliations)
    end

    it 'should have many project permissions' do
      should have_many(:project_permissions)
    end

    it 'should have many permitted_projects through project permissions' do
      should have_many(:permitted_projects).class_name('Project').through(:project_permissions).source(:project).conditions(is_deleted: false)
    end

    it 'should have many created_files' do
      should have_many(:created_files).class_name('DataFile').through(:permitted_projects).source(:data_files).with_foreign_key(:creator_id).conditions(is_deleted: false)
    end

    it 'should have many uploads through created_files' do
      should have_many(:uploads).through(:created_files)
    end

    it 'should have one system_permission' do
      should have_one(:system_permission)
    end

    it 'should have one api_key' do
      should have_one(:api_key)
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
    let(:project_permissions) { FactoryGirl.create_list(:project_permission, 5, user: subject) }
    let(:projects) { project_permissions.collect {|p| p.project} }
    let(:uploads) {
      uploads = []
      projects.each do |project|
        uploads << FactoryGirl.create(:upload, :completed, creator: subject, project: project)
      end
      uploads
    }
    let!(:files) {
      files = []
      uploads.each do |upload|
        files << FactoryGirl.create(:data_file, creator: subject, project: upload.project, upload: upload)
      end
      files
    }
    let!(:other_project) { FactoryGirl.create(:project, creator: subject) }
    let!(:other_upload) { FactoryGirl.create(:upload, :completed, creator: subject) }
    let!(:other_file) { FactoryGirl.create(:data_file, upload: other_upload) }
    let!(:deleted_project) { FactoryGirl.create(:project_permission, :deleted, user: subject).project }
    let(:deleted_upload) { FactoryGirl.create(:upload, :completed, creator: subject, project: projects.first)}
    let!(:deleted_file) { FactoryGirl.create(:data_file, :deleted, creator: subject, project: deleted_upload.project, upload: deleted_upload) }

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
