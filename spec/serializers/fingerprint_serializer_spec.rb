require 'rails_helper'

RSpec.describe FingerprintSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:fingerprint) }
  let(:is_logically_deleted) { false }

  it_behaves_like 'a json serializer' do
    it { is_expected.to have_key('algorithm') }
    it { is_expected.to have_key('value') }
    it { expect(subject["algorithm"]).to eq(resource.algorithm) }
    it { expect(subject["value"]).to eq(resource.value) }

    it_behaves_like 'a serializer with a serialized audit'
  end
end
