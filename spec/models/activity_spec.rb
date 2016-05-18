require 'rails_helper'

RSpec.describe Activity, type: :model do
  subject { activity }
  let(:activity) { FactoryGirl.create(:activity) }
  let(:deleted_activity) { FactoryGirl.create(:activity, :deleted) }
  let(:graphed_activity) { FactoryGirl.create(:activity, :graphed) }

  it_behaves_like 'an audited model'
  it_behaves_like 'a kind'
  it_behaves_like 'a graphed model', auto_create: true, logically_deleted: true do
    subject { graphed_activity }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :creator_id }
    it 'should belong to creator' do
      should belong_to(:creator).class_name('User')
    end

    it 'should allow is_deleted to be set' do
      should allow_value(true).for(:is_deleted)
      should allow_value(false).for(:is_deleted)
    end

    it 'should require ended_on to be greater than or equal to started_on' do
      subject.started_on = DateTime.now
      subject.ended_on = DateTime.now
      expect(subject).to be_valid

      subject.ended_on = subject.started_on + 10.minutes
      expect(subject).to be_valid

      subject.ended_on = subject.started_on - 10.minutes
      expect(subject).not_to be_valid
    end
  end
end
