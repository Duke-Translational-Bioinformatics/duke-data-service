require 'rails_helper'
require 'jwt'

RSpec.describe User, type: :model do
  let(:role_1) {FactoryGirl.create(:auth_role)}
  let(:role_2) {FactoryGirl.create(:auth_role)}
  let(:user_authentication_service) { FactoryGirl.create(:user_authentication_service, :populated) }
  subject { user_authentication_service.user }
  let(:resource_class) { User }
  let(:resource_serializer) { UserSerializer }
  let!(:resource) { subject }

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

    it 'should have many data_files' do
      should have_many(:data_files)
    end

    it 'should have many uploads through data_files' do
      should have_many(:uploads).through(:data_files)
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

    it 'should only allow auth_role_ids that exist' do
      should allow_value([role_1.id]).for(:auth_role_ids)
      should allow_value([]).for(:auth_role_ids)
      should_not allow_value(['foo']).for(:auth_role_ids)
    end
  end

  describe 'authorization roles' do
    subject {FactoryGirl.create(:user, :with_auth_role)}

    it 'should have an auth_roles method that returns AuthRole objects' do
      expect(subject).to respond_to(:auth_roles)
      expect(subject.auth_roles).to be_a Array
      subject.auth_role_ids.each do |role_id|
        role = AuthRole.where(id: role_id).first
        expect(subject.auth_roles).to include(role)
      end
    end

    it 'should have an auth_roles= method' do
      expect(subject).to respond_to(:auth_roles=)
      new_role_ids = [ role_1.id, role_2.id ]
      subject.auth_roles = new_role_ids
      expect(subject.auth_role_ids).to eq(new_role_ids)
    end

    describe 'without roles' do
      subject {FactoryGirl.create(:user)}

      it 'should have an auth_roles method that returns AuthRole objects' do
        expect(subject).to respond_to(:auth_roles)
        expect(subject.auth_roles).to be_a Array
      end
    end
  end

  describe 'usage' do
    subject { FactoryGirl.create(:user) }
    let(:projects) { FactoryGirl.create_list(:project, 5, creator_id: subject.id) }
    let(:files) {
      files = []
      projects.each do |project|
        upload = FactoryGirl.create(:upload, project_id: project.id)
        files << FactoryGirl.create(:data_file, creator_id: subject.id, project_id: project.id, upload_id: upload.id)
      end
      files
    }

    describe 'project_count' do
      let(:expected_count) { subject.projects.count }

      it 'should provide the count of user projects' do
        expect(subject).to respond_to('project_count')
        expect(subject.project_count).to eq(expected_count)
      end
    end

    describe 'file_count' do
      let(:expected_count) { subject.data_files.count }
      it 'should provide the count of user files' do
        expect(subject).to respond_to('file_count')
        expect(subject.file_count).to eq(expected_count)
      end
    end

    describe 'storage_bytes' do
      let(:expected_size) {
        expected_size = 0
        subject.uploads.each do |f|
          expected_size = f.size + expected_size
        end
        expected_size
      }
      it 'should provide the sum total of the size of all user uploads' do
        expect(subject).to respond_to('storage_bytes')
        expect(subject.storage_bytes).to eq(expected_size)
      end
    end

    describe 'UserUsageSerializer' do
      it 'should serialize user.usage to json' do
        serializer = UserUsageSerializer.new subject
        payload = serializer.to_json
        expect(payload).to be
        parsed_json = JSON.parse(payload)
        expect(parsed_json).to have_key('project_count')
        expect(parsed_json).to have_key('file_count')
        expect(parsed_json).to have_key('storage_bytes')
        expect(parsed_json['project_count']).to eq(subject.project_count)
        expect(parsed_json['file_count']).to eq(subject.file_count)
        expect(parsed_json['storage_bytes']).to eq(subject.storage_bytes)
      end
    end
  end

  describe 'UserSerializer' do
    let(:user_authentication_service) { FactoryGirl.create(:user_authentication_service, :populated) }
    subject { user_authentication_service.user }

    it 'should serialize user attributes to json' do
      serializer = UserSerializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to have_key('id')
      expect(parsed_json).to have_key('username')
      expect(parsed_json).to have_key('full_name')
      expect(parsed_json).to have_key('first_name')
      expect(parsed_json).to have_key('last_name')
      expect(parsed_json).to have_key('email')
      expect(parsed_json).to have_key('auth_provider')
      expect(parsed_json).to have_key('last_login_at')
      expect(parsed_json['id']).to eq(subject.id)
      expect(parsed_json['username']).to eq(subject.username)
      expect(parsed_json['full_name']).to eq(subject.display_name)
      expect(parsed_json['first_name']).to eq(subject.first_name)
      expect(parsed_json['last_name']).to eq(subject.last_name)
      expect(parsed_json['email']).to eq(subject.email)
      expect(parsed_json['auth_provider']).to have_key('uid')
      expect(parsed_json['auth_provider']).to have_key('source')
      expect(parsed_json['auth_provider']['uid']).to eq(user_authentication_service.uid)
      expect(parsed_json['auth_provider']['source']).to eq(user_authentication_service.authentication_service.name)
      expect(parsed_json['last_login_at'].to_json).to eq(subject.last_login_at.to_json)
    end
  end
end
