require 'rails_helper'

RSpec.describe Fingerprint, type: :model do
  subject { FactoryGirl.create(:fingerprint) }

  it_behaves_like 'an audited model'

  describe 'associations' do
    it { is_expected.to belong_to(:upload) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:upload_id) }
    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_presence_of(:algorithm) }
  end
end
