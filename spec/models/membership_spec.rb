require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe Membership, type: :model do
  describe 'validations' do
    subject {FactoryGirl.create(:membership)}

    it 'should have a user_id' do
      should validate_presence_of(:user_id)
    end

    it 'should have a project_id' do
      should validate_presence_of(:project_id)
    end
  end
end
