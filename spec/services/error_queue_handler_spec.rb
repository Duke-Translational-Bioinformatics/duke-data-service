require 'rails_helper'

RSpec.describe ErrorQueueHandler do
  include_context 'with sneakers'
  let(:bunny_session) { Sneakers::CONFIG[:connection] }
  let(:channel) { bunny_session.channel }
  let(:error_queue_name) { Sneakers::CONFIG[:retry_error_exchange] }
  let(:error_exchange) { channel.exchange(error_queue_name, type: :topic, durable: true) }
  let(:error_queue) { channel.queue(error_queue_name, durable: true) }
  let(:routing_key) { Faker::Internet.slug(nil, '_') }
  let(:sneakers_worker) {
    worker_queue_name = routing_key
    Class.new {
      include Sneakers::Worker
      from_queue worker_queue_name

      def work(msg)
        raise 'boom!'
      end
    }
  }

  before do
    Sneakers.configure(retry_max_times: 0)
    expect{sneakers_worker.new.run}.not_to raise_error
    expect(bunny_session.queue_exists?(error_queue_name)).to be_truthy
    expect{error_queue}.not_to raise_error
  end
  after do
    if channel.respond_to?(:queue_delete)
      channel.queue_delete(error_queue_name)
      channel.queue_delete(routing_key)
      channel.queue_delete(routing_key + '-retry')
    end
  end

  shared_examples 'expected error message format' do
    let(:message) { error_queue.pop }
    let(:payload) { JSON.parse(message.last) }
    let(:decoded_payload) { Base64.decode64(payload['payload']) }

    it { expect(error_queue.message_count).to be 1 }
    it { expect(message).to be_an Array }
    it { expect(message.first[:routing_key]).to eq routing_key }
    it { expect(decoded_payload).to eq original_payload }
  end

  def enqueue_mocked_message(msg, original_routing_key = routing_key)
    data = {
      payload: Base64.encode64(msg)
    }.to_json
    error_exchange.publish(data, {routing_key: original_routing_key})
    begin
      sleep 0.1
    end while Thread.list.count {|t| t.status == "run"} > 1
    msg
  end

  context 'Maxretry Handler generated message' do
    let(:original_payload) { Faker::Lorem.sentence }
    before(:each) do
      sneakers_worker.enqueue(original_payload)
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

    context 'with routing_key overridden' do
      let(:original_routing_key) { Faker::Internet.slug(nil, '_') }
      it { expect(error_queue.pop.first[:routing_key]).to eq original_routing_key }
    end
  end

  it { expect(error_queue.message_count).to be 0 }

  # Provide access to message count
  describe '#message_count' do
    it { is_expected.to respond_to(:message_count) }
    context 'with messages in error queue' do
      let(:expected_count) { Faker::Number.between(1, 10) }
      before { expected_count.times { enqueue_mocked_message(Faker::Lorem.sentence) } }
      it { expect(error_queue.message_count).to be expected_count }
      it { expect(subject.message_count).to be expected_count }
      it { expect{subject.message_count}.not_to change {error_queue.message_count} }
    end
  end

  def stub_message_response(payload, routing_key)
    id = Digest::SHA256.hexdigest(payload)
    {id: id, payload: payload, routing_key: routing_key}
  end

  # List decoded payloads
  #   - attributes
  #     - uniq id
  #     - routing key
  #     - payload
  #   - all messages return to error queue
  #   - gen uniq identifier from payload
  #     - Digest::SHA1.hexdigest(payload)
  #   - limit results returned with
  #     - routing key
  #     - limit by number of results
  describe '#messages' do
    it { is_expected.to respond_to(:messages).with(0).arguments }
    it { is_expected.to respond_to(:messages).with_keywords(:routing_key) }
    it { is_expected.to respond_to(:messages).with_keywords(:limit) }
    it { expect{subject.messages}.not_to raise_error }

    context 'with messages in error queue' do
      let(:queued_messages) {
        [
          stub_message_response(Faker::Lorem.sentence, routing_key),
          stub_message_response(Faker::Lorem.sentence, Faker::Internet.slug(nil, '_')),
          stub_message_response(Faker::Lorem.sentence, routing_key)
        ]
      }
      before(:each) do
        queued_messages.each {|m| enqueue_mocked_message(m[:payload], m[:routing_key])}
      end
      it { expect(error_queue.message_count).to be queued_messages.length }
      it { expect{subject.messages}.not_to change {error_queue.message_count} }
      it { expect(subject.messages).to be_a Array }
      it { expect(subject.messages.count).to eq queued_messages.count }
      it { expect(subject.messages).to eq queued_messages }

      context 'when limit keyword is set' do
        let(:expected_messages) {
          queued_messages.take(2)
        }
        it { expect(expected_messages.length).to eq 2 }
        it { expect(subject.messages(limit: 2)).to eq expected_messages }
        it { expect{subject.messages(limit: 2)}.not_to change {error_queue.message_count} }
      end

      context 'when routing_key keyword is set' do
        let(:expected_messages) {
          queued_messages.select {|m| m[:routing_key] == routing_key}
        }
        it { expect(expected_messages).not_to be_empty }
        it { expect(expected_messages.length).to be < queued_messages.length }
        it { expect(subject.messages(routing_key: routing_key)).to eq expected_messages }
        it { expect{subject.messages(routing_key: routing_key)}.not_to change {error_queue.message_count} }
        it { expect(subject.messages(routing_key: 'does_not_exist')).to eq [] }
        it { expect{subject.messages(routing_key: 'does_not_exist')}.not_to change {error_queue.message_count} }
      end

      context 'when routing_key and limit is set' do
        let(:expected_messages) {
          (queued_messages.select {|m| m[:routing_key] == routing_key}).take(2)
        }
        it { expect(expected_messages.length).to eq 2 }
        it { expect(subject.messages(routing_key: routing_key, limit: 2)).to eq expected_messages }
        it { expect{subject.messages(routing_key: routing_key, limit: 2)}.not_to change {error_queue.message_count} }
        it { expect(subject.messages(routing_key: 'does_not_exist', limit: 2)).to eq [] }
        it { expect{subject.messages(routing_key: 'does_not_exist', limit: 2)}.not_to change {error_queue.message_count} }
      end
    end
  end

  # Requeue single message to message_gateway
  #   - use uniq id
  #     - allow partial match
  #   - message removed from error queue on success
  describe '#requeue_message' do
    it { is_expected.to respond_to(:requeue_message).with(1).argument }
  end

  # Requeue all messages to message_gateway
  #   - messages removed from error queue on success
  describe '#requeue_all' do
    it { is_expected.to respond_to(:requeue_all) }
  end

  # Requeue all messages for routing_key to message_gateway
  #   - messages removed from error queue on success
  #   - limit results returned with
  #     - routing key
  #     - limit by number of results
  describe '#requeue_messages' do
    it { is_expected.not_to respond_to(:requeue_messages).with(0).arguments }
    it { is_expected.to respond_to(:requeue_messages).with_keywords(:routing_key) }
    it { is_expected.to respond_to(:requeue_messages).with_keywords(:routing_key, :limit) }
  end
end
