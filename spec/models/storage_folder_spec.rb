require 'rails_helper'

RSpec.describe StorageFolder, type: :model do
  describe 'validations' do
    subject {FactoryGirl.create(:storage_folder)}

    it 'should have a project_id' do
      should validate_presence_of(:project_id)
    end

    it 'should have a unique name' do
      should validate_presence_of(:name)
      should validate_uniqueness_of(:name)
    end

    it 'should have a description' do
      should validate_presence_of(:description)
    end

    it 'should have a storage_service_uuid' do
      should validate_presence_of(:storage_service_uuid)
    end
  end
end
