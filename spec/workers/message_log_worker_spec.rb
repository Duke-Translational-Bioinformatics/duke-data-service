require 'rails_helper'

RSpec.describe MessageLogWorker do
  let(:gateway_exchange_name) { Sneakers::CONFIG[:exchange] }
  let(:queue_name) { 'message_log' }

  it { expect(described_class).to include(Sneakers::Worker) }
  it { expect(subject.queue.name).to eq(queue_name) }
  it { expect(subject.opts[:exchange]).to eq(gateway_exchange_name) }
  it { expect(subject.opts[:exchange_options][:type]).to eq(:fanout) }
  it { expect(subject.opts[:exchange_options][:durable]).to be_truthy }

  it { is_expected.not_to respond_to(:work) }
  it { is_expected.to respond_to(:work_with_params).with(3).arguments }

  describe '#work_with_params' do
    let(:message) { Faker::Lorem.words(5) }
    let(:delivery_info) { {exchange: Faker::Internet.slug, id: Faker::Number.digit} }
    let(:metadata) { :baz }
    let(:method) { subject.work_with_params(message, delivery_info, metadata) }
    let(:ack) { subject.ack! }
    it { expect(ack).not_to be_nil }

    it_behaves_like 'an elasticsearch indexer' do
      include_context 'with a single document indexed'

      it { expect(method).to eq ack }
    end
  end
end
