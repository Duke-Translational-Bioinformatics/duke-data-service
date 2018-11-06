require 'rails_helper'

RSpec.describe IdentityProvider, type: :model do
  subject { IdentityProvider.new }

  it_behaves_like 'an IdentityProvider'

  describe 'validations' do
    it { is_expected.to validate_presence_of :host }
    it { is_expected.to validate_presence_of :port }
  end

  describe 'interface' do
    describe '#affiliates' do
      it { expect{ subject.affiliates }.to raise_error(NotImplementedError) }
      it { expect{ subject.affiliates(full_name_contains: 'foo') }.to raise_error(NotImplementedError) }
    end

    describe '#affiliate' do
      it { expect{ subject.affiliate('foo') }.to raise_error(NotImplementedError) }
    end
  end
end
