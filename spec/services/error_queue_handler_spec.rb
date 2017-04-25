require 'rails_helper'

RSpec.describe ErrorQueueHandler do
  # Provide access to message count
  describe '#message_count' do
    it { is_expected.to respond_to(:message_count) }
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
