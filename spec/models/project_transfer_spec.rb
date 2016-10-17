require 'rails_helper'

RSpec.describe ProjectTransfer, type: :model do
  it_behaves_like 'an audited model'
  let(:non_pending_statuses) { %w{accepted canceled rejected} }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:project_permissions).through(:project) }
    it { is_expected.to belong_to(:from_user).class_name('User') }
    it { is_expected.to have_many(:project_transfer_users) }
    it { is_expected.to have_many(:to_users).through(:project_transfer_users) }
  end

  describe 'validations' do
    let!(:existing_project_transfer) { FactoryGirl.create(:project_transfer, :accepted) }
    subject { FactoryGirl.build(:project_transfer, project: existing_project_transfer.project) }

    it { is_expected.to validate_presence_of :from_user_id }
    it { is_expected.to validate_presence_of :project }

    it { is_expected.to allow_value('pending').for(:status) }
    it { is_expected.to allow_values(*non_pending_statuses).for(:status) }

    context 'when pending transfer exists' do
      let!(:existing_project_transfer) { FactoryGirl.create(:project_transfer, :pending) }
      it { is_expected.to validate_uniqueness_of(:status).
        scoped_to(:project_id).case_insensitive.
        with_message('Pending transfer already exists') }
      it { is_expected.not_to allow_value('pending').for(:status) }
      it { is_expected.to allow_values(*non_pending_statuses).for(:status) }
    end
  end
end
