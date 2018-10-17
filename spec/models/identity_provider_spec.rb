require 'rails_helper'

RSpec.describe IdentityProvider, type: :model do
  subject { IdentityProvider.new }

  describe 'validations' do
    it { is_expected.to validate_presence_of :host }
    it { is_expected.to validate_presence_of :port }
  end

  describe 'interface' do
    describe '#affiliates' do
      it { is_expected.to respond_to(:affiliates) }
      it { is_expected.to respond_to(:affiliates).with(1).argument }
      it { expect{ subject.affiliates }.to raise_error(NotImplementedError) }
      it { expect{ subject.affiliates('foo') }.to raise_error(NotImplementedError) }
    end

    describe '#affiliate' do
      it { is_expected.to respond_to(:affiliate).with(1).argument }
      it { expect{ subject.affiliate('foo') }.to raise_error(NotImplementedError) }
    end
  end
end
