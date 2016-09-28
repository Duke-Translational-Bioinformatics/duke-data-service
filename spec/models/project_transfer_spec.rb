require 'rails_helper'

RSpec.describe ProjectTransfer, type: :model do
  it_behaves_like 'an audited model'

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:from_user).class_name('User') }
    it { is_expected.to have_many(:project_transfer_users) }
    it { is_expected.to have_many(:to_users).through(:project_transfer_users) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :project_id }
    it { is_expected.to validate_presence_of :from_user_id }

  end
end
