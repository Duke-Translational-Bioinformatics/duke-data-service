require 'rails_helper'

RSpec.describe Activity, type: :model do
  subject { activity }
  let(:activity) { FactoryGirl.create(:activity) }
  let(:deleted_activity) { FactoryGirl.create(:activity, :deleted) }

  it_behaves_like 'an audited model'
  it_behaves_like 'a kind'
  it_behaves_like 'a graphed model', auto_create: true, logically_deleted: true

  describe 'validations' do
    it { is_expected.to validate_presence_of :name }

    it 'should allow is_deleted to be set' do
      should allow_value(true).for(:is_deleted)
      should allow_value(false).for(:is_deleted)
    end
  end
end
