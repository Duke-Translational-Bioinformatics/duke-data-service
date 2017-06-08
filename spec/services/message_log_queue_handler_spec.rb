require 'rails_helper'

RSpec.describe MessageLogQueueHandler do
  include_context 'with sneakers'

  let(:bunny_session) { Sneakers::CONFIG[:connection] }
  let(:channel) { bunny_session.channel }
  let(:gateway_exchange_name) { Sneakers::CONFIG[:exchange] }
  let(:gateway_exchange) { channel.exchange(gateway_exchange_name, type: :fanout, durable: true) }
  let(:message_log_queue_name) { 'message_log' }
  let(:message_log_queue) { channel.queue(message_log_queue_name, durable: true) }
  let(:message_log_worker) { MessageLogWorker.new }

  before do
    expect{message_log_worker.run}.not_to raise_error
    expect{message_log_worker.stop}.not_to raise_error
    expect(bunny_session.queue_exists?(message_log_queue_name)).to be_truthy
    expect{message_log_queue}.not_to raise_error
  end
  after do
    if channel.respond_to?(:queue_delete)
      channel.queue_delete(message_log_queue_name)
    end
  end

  def stubbed_message(payload, routing_key)
    {payload: {'job_info' => payload}.to_json, routing_key: routing_key}
  end

  def enqueue_message(msg, original_routing_key = routing_key)
    gateway_exchange.publish(msg, {routing_key: original_routing_key, content_type: 'application/octet-stream'})
    begin
      sleep 0.1
    end while Thread.list.count {|t| t.status == "run"} > 1
    msg
  end

  RSpec::Matchers.define :delivery_info_with_routing_key do |routing_key|
      match do |actual|
        actual && actual[:delivery_tag] && actual[:routing_key] == routing_key
      end
  end
  RSpec::Matchers.define :message_meta_data_with_content_type do |content_type|
      match do |actual|
        actual && actual[:content_type] == content_type
      end
  end

  describe '#index_messages' do
    before(:each) { expect(message_log_queue.message_count).to eq 0 }

    it { is_expected.to respond_to(:index_messages).with(0).arguments }

    context 'with messages in message_log queue' do
      let(:queued_messages) {
        [
          stubbed_message(Faker::Lorem.sentence, Faker::Internet.slug(nil, '_')),
          stubbed_message(Faker::Lorem.sentence, Faker::Internet.slug(nil, '_')),
          stubbed_message(Faker::Lorem.sentence, Faker::Internet.slug(nil, '_'))
        ]
      }
      before(:each) do
        queued_messages.each {|m| enqueue_message(m[:payload], m[:routing_key])}
        expect(message_log_queue.message_count).to eq queued_messages.length
        expect(MessageLogWorker).to receive(:new).and_return(message_log_worker)
        queued_messages.each do |msg|
          expect(message_log_worker).to receive(:work_with_params).with(
            msg[:payload],
            delivery_info_with_routing_key(msg[:routing_key]),
            message_meta_data_with_content_type('application/octet-stream')
          ).and_call_original
        end
      end
      it { expect{subject.index_messages}.to change{message_log_queue.message_count}.by(-queued_messages.length) }
    end
  end
end
