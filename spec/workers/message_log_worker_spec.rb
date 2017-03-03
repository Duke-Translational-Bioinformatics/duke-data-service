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
  end
end
