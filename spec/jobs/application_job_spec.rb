require 'rails_helper'

RSpec.describe ApplicationJob, type: :job do
  let(:gateway_exchange_name) { 'test.'+Faker::Internet.slug }
  let(:distributor_exchange_name) { 'active_jobs' }
  let(:message_log_name) { 'message_log' }
  let(:queue_name) { Faker::Internet.slug(nil, '_').to_sym }
  let(:child_class) {
    Class.new(described_class) do
      queue_as queue_name
      def perform
        true
      end
    end
  }
  let(:sneakers_config) { Sneakers::CONFIG }

  before do
    Sneakers.configure(exchange: gateway_exchange_name)
    Sneakers.logger = Rails.logger # Must reset logger whenever configure is called
  end
  after do
    conn = Bunny.new(sneakers_config[:amqp])
    conn.start.with_channel do |channel|
      channel.exchange_delete(gateway_exchange_name)
      channel.exchange_delete(distributor_exchange_name)
      channel.queue_delete(message_log_name)
    end
    conn.close
  end
  
  it { is_expected.to be_a ActiveJob::Base }
  it { expect{described_class.perform_now}.to raise_error(NotImplementedError) }

  it { expect(described_class).to respond_to(:gateway_exchange) }
  describe '::gateway_exchange' do
    let(:gateway_exchange) { described_class.gateway_exchange }
    it { expect(gateway_exchange).to be_a Bunny::Exchange }
    it { expect(gateway_exchange.name).to eq(gateway_exchange_name) }
    it { expect(gateway_exchange.type).to eq(sneakers_config[:exchange_options][:type]) }
    it { expect(gateway_exchange).to be_durable }
  end

  it { expect(described_class).to respond_to(:distributor_exchange) }
  describe '::distributor_exchange' do
    let(:distributor_exchange) { described_class.distributor_exchange }
    it { expect(distributor_exchange).to be_a Bunny::Exchange }
    it { expect(distributor_exchange.name).to eq(distributor_exchange_name) }
    it { expect(distributor_exchange.type).to eq(:direct) }
    it { expect(distributor_exchange).to be_durable }
  end

  it { expect(described_class).to respond_to(:message_log_queue) }
  describe '::message_log_queue' do
    let(:message_log_queue) { described_class.message_log_queue }
    it { expect(message_log_queue).to be_a Bunny::Queue }
    it { expect(message_log_queue.name).to eq(message_log_name) }
    it { expect(message_log_queue).to be_durable }
  end

  context 'child_class' do
    it { expect{child_class.perform_now}.not_to raise_error }
    it { expect{child_class.perform_later}.not_to raise_error }
  end
end
