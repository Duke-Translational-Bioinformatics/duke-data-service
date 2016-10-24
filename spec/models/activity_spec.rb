require 'rails_helper'

RSpec.describe Activity, type: :model do
  subject { activity }
  let(:activity) { FactoryGirl.create(:activity) }
  let(:deleted_activity) { FactoryGirl.create(:activity, :deleted) }

  it_behaves_like 'an audited model'
  it_behaves_like 'a kind'
  it_behaves_like 'a logically deleted model'
  it_behaves_like 'a graphed node', auto_create: true, logically_deleted: true

  context 'started_on' do
    context 'default' do
      it 'is expected to be set to the current time' do
        before_time = DateTime.now
        expect(subject).to be_persisted
        expect(subject.started_on).not_to be_nil
        expect(subject.started_on).to be >= before_time
        expect(subject.started_on).to be <= DateTime.now
      end
    end

    context 'set by user' do
      it 'is expected to be set to the user supplied value' do
        user_supplied_started_on = 10.minutes.ago
        new_record = FactoryGirl.create(:activity, started_on: user_supplied_started_on)
        new_record.reload
        expect(new_record.started_on.to_i).to be == user_supplied_started_on.to_i
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:creator).class_name('User') }
    it { is_expected.to have_many(:generated_by_activity_prov_relations) }
    it { is_expected.to have_many(:invalidated_by_activity_prov_relations) }
    it { is_expected.to have_many(:used_prov_relations) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :creator_id }

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
