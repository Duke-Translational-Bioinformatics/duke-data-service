require 'rails_helper'

RSpec.describe ApiKey, type: :model do
  subject { FactoryBot.create(:api_key) }

  it 'should belong_to user' do
    should belong_to :user
  end

  it 'should belong_to software_agent' do
    should belong_to :software_agent
  end

  it 'should require key' do
    should validate_presence_of :key
  end

  it_behaves_like 'an audited model'
end
