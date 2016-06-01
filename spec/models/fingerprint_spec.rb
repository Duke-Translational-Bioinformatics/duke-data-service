require 'rails_helper'

RSpec.describe Fingerprint, type: :model do
  subject { FactoryGirl.create(:fingerprint) }
  let(:algorithms) { %w{md5 sha256 sha1} }

  it_behaves_like 'an audited model'

  describe 'associations' do
    it { is_expected.to belong_to(:upload) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:upload_id) }
    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_presence_of(:algorithm) }
    it { is_expected.to validate_inclusion_of(:algorithm).in_array(algorithms) }
  end

  describe '#available_algorithms' do
    it { is_expected.to respond_to(:available_algorithms) }
    it { expect(subject.available_algorithms).to eq(algorithms)}
  end
end
