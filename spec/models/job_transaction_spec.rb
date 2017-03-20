require 'rails_helper'

RSpec.describe JobTransaction, type: :model do
  subject { FactoryGirl.create(:job_transaction) }

  describe 'validations' do
    it {
      is_expected.to belong_to(:transactionable)
      is_expected.to validate_presence_of(:transactionable)
      is_expected.to validate_presence_of(:key)
      is_expected.to validate_uniqueness_of(:key).scoped_to(:transactionable_id).case_insensitive
      is_expected.to validate_presence_of(:state)
    }
  end
end
