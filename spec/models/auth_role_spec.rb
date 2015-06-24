require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe AuthRole, type: :model do
  describe 'validations' do
    subject {FactoryGirl.create(:auth_role)}

    it 'should require a unique text_id' do
      should validate_presence_of(:text_id)
      should validate_uniqueness_of(:text_id)
    end

    it 'should require a name' do
      should validate_presence_of(:name)
    end
    
    it 'should require a description' do
      should validate_presence_of(:description)
    end
    
    it 'should require at least one permission' do
      should validate_presence_of(:permissions)
      should allow_value(['foo']).for(:permissions)
      should allow_value(['foo', 'bar']).for(:permissions)
      should_not allow_value([]).for(:permissions)
    end
    
    it 'should require at least one context' do
      should validate_presence_of(:contexts)
      should allow_value(['foo']).for(:contexts)
      should allow_value(['foo', 'bar']).for(:contexts)
      should_not allow_value([]).for(:contexts)
    end
  end
end
