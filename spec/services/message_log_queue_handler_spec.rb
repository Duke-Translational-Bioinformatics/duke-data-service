require 'rails_helper'

RSpec.describe MessageLogQueueHandler do
  include_context 'with sneakers'

  let(:default_duration) { 300 }
  describe '::DEFAULT_WORK_DURATION' do
    it { expect(described_class).to be_const_defined(:DEFAULT_WORK_DURATION) }
    it { expect(described_class::DEFAULT_WORK_DURATION).to eq(default_duration) }
  end
  describe '#work_duration attr_accessor' do
    it { is_expected.to respond_to(:work_duration).with(0).argument }
    it { is_expected.to respond_to(:work_duration=).with(1).argument }
    it { expect(subject.work_duration).to eq(default_duration) }
    context 'once set' do
      let(:limit_value) { Faker::Number.between(from: 1, to: 10) }
      before { subject.work_duration = limit_value }
      it { expect(subject.work_duration).to eq limit_value }
    end
  end

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
    {payload: {'job_info' => payload}.to_json, routing_key: routing_key, content_type: Faker::File.mime_type}
  end

  def enqueue_message(msg, original_routing_key = routing_key, content_type = 'application/octet-stream')
    gateway_exchange.publish(msg, {routing_key: original_routing_key, content_type: content_type})
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
          stubbed_message(Faker::Lorem.sentence, Faker::Internet.slug(words: nil, glue: '_')),
          stubbed_message(Faker::Lorem.sentence, Faker::Internet.slug(words: nil, glue: '_')),
          stubbed_message(Faker::Lorem.sentence, Faker::Internet.slug(words: nil, glue: '_'))
        ]
      }
      before(:each) do
        queued_messages.each {|m| enqueue_message(m[:payload], m[:routing_key], m[:content_type])}
        expect(message_log_queue.message_count).to eq queued_messages.length
      end
      it_behaves_like 'an elasticsearch indexer' do
        let(:mocked_duration) { 0.25 }
        before(:each) do
          queued_messages.each do |msg|
            expect_any_instance_of(MessageLogWorker).to receive(:work_with_params).with(
              msg[:payload],
              delivery_info_with_routing_key(msg[:routing_key]),
              message_meta_data_with_content_type(msg[:content_type])
            ).and_call_original
            allow(subject).to receive(:sleep) { sleep(mocked_duration) }
          end
        end
        it 'stops threads before returning' do
          expect{subject.index_messages}.not_to change{Thread.list.count}
        end
        context 'with default work_duration' do
          before(:each) do
            is_expected.to receive(:sleep).with(default_duration) { sleep(mocked_duration) }
          end
          it { expect{subject.index_messages}.to change{message_log_queue.message_count}.by(-queued_messages.length) }
        end
        context 'with custom work_duration' do
          let(:custom_duration) { Faker::Number.between(from: 1, to: 10) }
          before(:each) do
            subject.work_duration = custom_duration
            is_expected.to receive(:sleep).with(custom_duration) { sleep(mocked_duration) }
          end
          it 'indexes queued messages' do
            expect{subject.index_messages}.not_to raise_error
            expect(new_documents.length).to eq(queued_messages.length)
          end
        end
      end
    end
  end
end
