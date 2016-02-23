require 'rails_helper'

RSpec.describe UserApiSecret, type: :model do
  let(:user) { FactoryGirl.create(:user) }
  subject { FactoryGirl.create(:user_api_secret, user: user ) }

  it 'should belong_to user' do
    should belong_to :user
  end
  it 'should require user_id' do
    should validate_presence_of :user_id
  end
  it 'should require key' do
    should validate_presence_of :key
  end

  it_behaves_like 'an audited model'
end
