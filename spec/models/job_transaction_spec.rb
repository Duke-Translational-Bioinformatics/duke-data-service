require 'rails_helper'

RSpec.describe JobTransaction, type: :model do
  subject { FactoryGirl.create(:job_transaction) }

  describe 'validations' do
    it {
      is_expected.to belong_to(:transactionable)
      is_expected.to validate_presence_of(:transactionable_id)
      is_expected.to validate_presence_of(:transactionable_type)
      is_expected.to validate_presence_of(:request_id)
      is_expected.to validate_presence_of(:key)
      is_expected.to validate_presence_of(:state)
    }
  end
end
