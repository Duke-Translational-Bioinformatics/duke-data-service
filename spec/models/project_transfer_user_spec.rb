require 'rails_helper'

RSpec.describe ProjectTransferUser, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:project_transfer) }
    it { is_expected.to belong_to(:to_user).class_name('User') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :project_transfer }
    it { is_expected.to validate_presence_of :to_user }
  end
end
