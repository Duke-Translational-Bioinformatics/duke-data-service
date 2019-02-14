require 'rails_helper'

RSpec.describe ErrorQueueHandler do
  include_context 'with sneakers'
  include_context 'error queue message utilities'

  let(:class_deprecation_exception) { "ErrorQueueHandler is deprecated due to incompatibilities with the ExponentialBackoffHandler." }
  let(:bunny_session) { Sneakers::CONFIG[:connection] }
  let(:channel) { bunny_session.channel }
  let(:error_queue_name) { "#{prefixed_queue_name}.error" }
  let(:error_exchange_name) { "#{prefixed_queue_name}.dlx" }
  let(:error_exchange) { channel.exchange(error_exchange_name, type: :topic, durable: true) }
  let(:error_queue) { channel.queue(error_queue_name, durable: true) }
  let(:queue_name) { Faker::Internet.slug(nil, '_') }
  let(:prefix) { Rails.application.config.active_job.queue_name_prefix }
  let(:prefix_delimiter) { Rails.application.config.active_job.queue_name_delimiter }
  let(:prefixed_queue_name) { "#{prefix}#{prefix_delimiter}#{queue_name}"}
  let(:routing_key) { prefixed_queue_name }
  let(:worker_queue) { channel.queue(
    prefixed_queue_name,
    durable: true,
    arguments: {
      'x-dead-letter-exchange' => "#{prefixed_queue_name}.dlx",
      'x-dead-letter-routing-key' => "#{prefixed_queue_name}.error"
    }
  ) }
  let(:job_class_name) {|example| "error_queue_handler_spec#{example.metadata[:scoped_id].gsub(':','x')}_job".classify }
  let(:application_job) {
    job_queue_name = queue_name
    Object.const_set(job_class_name, Class.new(ApplicationJob) do
      queue_as job_queue_name

      def perform
        raise 'boom!'
      end
      def self.should_be_registered_worker?
        false
      end
    end)
  }
  let(:sneakers_worker_class) { application_job.job_wrapper }
  let(:sneakers_worker) { sneakers_worker_class.new }

  before do
    Sneakers.configure(retry_max_times: 0)
    Sneakers.configure(max_retries: 0)
    expect{sneakers_worker.run}.not_to raise_error
    expect(bunny_session.queue_exists?(error_queue_name)).to be_truthy
    expect(bunny_session.queue_exists?(prefixed_queue_name)).to be_truthy
    expect{error_queue}.not_to raise_error
  end
  after do
    if channel.respond_to?(:queue_delete)
      channel.queue_delete(error_queue_name)
      channel.queue_delete(prefixed_queue_name)
      channel.queue_delete(prefixed_queue_name + '-retry')
    end
  end

  shared_context 'with a problem message' do
    let(:problem_message) { queued_messages.first }
    before(:each) do
      allow(subject).to receive(:republish_message).and_call_original
      expect(subject).to receive(:republish_message).with(
        anything,
        problem_message
      ).and_raise(Bunny::Exception)
    end
  end

  shared_examples 'expected error message format' do
    let(:message) { error_queue.pop }
    let(:payload) { message.last }
    let(:decoded_payload) { payload }

    it { expect(error_queue.message_count).to eq 1 }
    it { expect(message).to be_an Array }
    it { expect(message.first[:routing_key]).to eq routing_key }
    it { expect(decoded_payload).to eq original_payload }
  end

  def enqueue_mocked_message(msg, original_routing_key = routing_key)
    data = msg
    error_exchange.publish(data, {routing_key: original_routing_key})
    begin
      sleep 0.1
    end while Thread.list.count {|t| t.status == "run"} > 1
    msg
  end

  context 'ExponentialBackoffHandler generated message' do
    let(:original_payload) { Faker::Lorem.sentence }
    before(:each) do
      sneakers_worker_class.enqueue(original_payload)
      begin
        sleep 0.1
      end while Thread.list.count {|t| t.status == "run"} > 1
    end

    it_behaves_like 'expected error message format'
  end

  context 'enqueue_mocked_message generated message' do
    let(:original_payload) { Faker::Lorem.sentence }
    let(:original_routing_key) { routing_key }
    before(:each) do
      expect(enqueue_mocked_message(original_payload, original_routing_key)).to eq original_payload
    end

    it_behaves_like 'expected error message format'
  end

  it { expect(error_queue.message_count).to be 0 }

  describe '#message_count' do
    it { is_expected.to respond_to(:message_count) }
    it { expect { subject.message_count }.to raise_error(class_deprecation_exception) }
  end

  describe '#messages' do
    it { is_expected.to respond_to(:messages).with(0).arguments }
    it { is_expected.to respond_to(:messages).with_keywords(:routing_key) }
    it { is_expected.to respond_to(:messages).with_keywords(:limit) }
    it { expect { subject.messages }.to raise_error(class_deprecation_exception) }
  end

  describe '#requeue_message' do
    it { is_expected.to respond_to(:requeue_message).with(1).argument }
    it { expect{subject.requeue_message('does_not_exist')}.to raise_error(class_deprecation_exception) }
  end

  describe '#requeue_all' do
    it { is_expected.to respond_to(:requeue_all) }
    it { expect{subject.requeue_all}.to raise_error(class_deprecation_exception) }
  end

  describe '#requeue_messages' do
    it { is_expected.not_to respond_to(:requeue_messages).with(0).arguments }
    it { is_expected.to respond_to(:requeue_messages).with_keywords(:routing_key) }
    it { is_expected.to respond_to(:requeue_messages).with_keywords(:routing_key, :limit) }
    it { expect{subject.requeue_messages(routing_key: 'does_not_exist')}.to raise_error(class_deprecation_exception) }
  end
end
