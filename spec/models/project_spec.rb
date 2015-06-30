require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe Project, type: :model do
  describe 'validations' do
    subject {FactoryGirl.create(:project)}

    it 'should have a unique project name' do
      should validate_presence_of(:name)
      should validate_uniqueness_of(:name)
    end

    it 'should have a description' do
      should validate_presence_of(:description)
    end

    it 'should have a creator_id' do
      should validate_presence_of(:creator_id)
    end
  end
end
