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
    let!(:existing_project_transfer) { FactoryGirl.create(:project_transfer, :accepted, :skip_validation) }
    subject { FactoryGirl.build(:project_transfer, project: existing_project_transfer.project) }

    it { is_expected.to validate_presence_of :project }
    it { is_expected.to validate_presence_of :from_user }
    it { is_expected.to validate_presence_of :project_transfer_users }

    it { is_expected.to allow_value('pending').for(:status) }
    it { is_expected.to allow_values(*non_pending_statuses).for(:status) }

    context 'when pending transfer exists' do
      let!(:existing_project_transfer) { FactoryGirl.create(:project_transfer, :pending, :skip_validation) }
      it { is_expected.to validate_uniqueness_of(:status).
        scoped_to(:project_id).ignoring_case_sensitivity.
        with_message('Pending transfer already exists') }
      it { is_expected.not_to allow_value('pending').for(:status) }
      it { is_expected.to allow_values(*non_pending_statuses).for(:status) }
    end
    context 'with exisiting project transfer' do
      subject { FactoryGirl.create(:project_transfer, :with_to_users, status: status) }
      context 'status is pending' do
        let(:status) { :pending }
        it { is_expected.to allow_values(*non_pending_statuses).for(:status) }
        it { is_expected.to allow_value('This is a valid status comment').for(:status_comment) }
      end
      context 'status is rejected' do
        let(:status) { :rejected }
        it { is_expected.not_to allow_values(*%w{accepted pending canceled}).for(:status) }
        it { is_expected.not_to allow_value('This is a valid status comment').for(:status_comment) }
      end
      context 'status is accepted' do
        let(:status) { :accepted }
        it { is_expected.not_to allow_values(*%w{canceled pending rejected}).for(:status) }
        it { is_expected.not_to allow_value('This is a valid status comment').for(:status_comment) }
      end
      context 'status is canceled' do
        let(:status) { :canceled }
        it { is_expected.not_to allow_values(*%w{accepted pending rejected}).for(:status) }
        it { is_expected.not_to allow_value('This is a valid status comment').for(:status_comment) }
      end
    end
  end

  describe 'status with enum' do
    it { is_expected.to define_enum_for(:status).
      with([:pending, :rejected, :accepted, :canceled]) }
  end
end
