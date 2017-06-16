require 'rails_helper'

describe 'queue:errors:message_count' do
  include_context "rake"
  include_context 'error queue message utilities'
  let(:error_queue_handler) { instance_double(ErrorQueueHandler) }
  let(:routing_key) { Faker::Internet.slug(nil, '_') }
  let(:message_count) { Faker::Number.digit }

  before { expect(ErrorQueueHandler).to receive(:new).and_return(error_queue_handler) }
  it {
    expect(error_queue_handler).to receive(:message_count).and_return(message_count)
    invoke_task(expected_stdout: /Error queue message count is #{message_count}/)
  }
end

describe 'queue:errors:messages' do
  include_context "rake"
  include_context 'error queue message utilities'
  let(:error_queue_handler) { instance_double(ErrorQueueHandler) }
  let(:routing_key) { Faker::Internet.slug(nil, '_') }
  let(:serialized_messages) {[
    stub_message_response(Faker::Lorem.sentence, routing_key),
    stub_message_response(Faker::Lorem.sentence, Faker::Internet.slug(nil, '_')),
    stub_message_response(Faker::Lorem.sentence, routing_key)
  ]}
  def output_format(msg)
    /#{msg[:id]} \[#{msg[:routing_key]}\] "#{msg[:payload]}"/
  end

  before(:each) do
    expect(ErrorQueueHandler).to receive(:new).and_return(error_queue_handler)
    allow(error_queue_handler).to receive(:messages).and_return(serialized_messages)
  end
  it { invoke_task(expected_stdout: output_format(serialized_messages.first)) }
  it { invoke_task(expected_stdout: output_format(serialized_messages.second)) }
  it { invoke_task(expected_stdout: output_format(serialized_messages.third)) }

  context 'with ROUTING_KEY' do
    include_context 'with env_override'
    let(:env_override) { {
      'ROUTING_KEY' => routing_key
    } }
    let(:serialized_messages) {[
      stub_message_response(Faker::Lorem.sentence, routing_key),
      stub_message_response(Faker::Lorem.sentence, routing_key)
    ]}
    before(:each) do
      expect(error_queue_handler).to receive(:messages).with(routing_key: routing_key, limit: nil).and_return(serialized_messages)
    end
    it { invoke_task(expected_stdout: output_format(serialized_messages.first)) }
    it { invoke_task(expected_stdout: output_format(serialized_messages.second)) }
  end

  context 'with LIMIT' do
    include_context 'with env_override'
    let(:limit) { serialized_messages.length }
    let(:env_override) { {
      'LIMIT' => limit
    } }
    let(:serialized_messages) {[
      stub_message_response(Faker::Lorem.sentence, routing_key),
      stub_message_response(Faker::Lorem.sentence, Faker::Internet.slug(nil, '_'))
    ]}
    before(:each) do
      expect(error_queue_handler).to receive(:messages).with(routing_key: nil, limit: limit).and_return(serialized_messages)
    end
    it { invoke_task(expected_stdout: output_format(serialized_messages.first)) }
    it { invoke_task(expected_stdout: output_format(serialized_messages.second)) }
  end

  context 'with ROUTING_KEY and LIMIT' do
    include_context 'with env_override'
    let(:limit) { serialized_messages.length }
    let(:env_override) { {
      'ROUTING_KEY' => routing_key,
      'LIMIT' => limit
    } }
    let(:serialized_messages) {[
      stub_message_response(Faker::Lorem.sentence, routing_key),
      stub_message_response(Faker::Lorem.sentence, routing_key)
    ]}
    before(:each) do
      expect(error_queue_handler).to receive(:messages).with(routing_key: routing_key, limit: limit).and_return(serialized_messages)
    end
    it { invoke_task(expected_stdout: output_format(serialized_messages.first)) }
    it { invoke_task(expected_stdout: output_format(serialized_messages.second)) }
  end
end

describe 'queue:errors:requeue_message' do
  include_context "rake"
  include_context 'error queue message utilities'
  let(:error_queue_handler) { instance_double(ErrorQueueHandler) }
  let(:serialized_message) {
    stub_message_response(Faker::Lorem.sentence, Faker::Internet.slug(nil, '_'))
  }
  def output_format(msg)
    /#{msg[:id]} \[#{msg[:routing_key]}\] "#{msg[:payload]}"\nMessage requeue successful!/
  end

  it { invoke_task(expected_stderr: /MESSAGE_ID required; set to hex id of message to requeue./) }

  context 'with MESSAGE_ID' do
    include_context 'with env_override'
    let(:env_override) { {
      'MESSAGE_ID' => serialized_message[:id]
    } }
    before(:each) do
      expect(ErrorQueueHandler).to receive(:new).and_return(error_queue_handler)
    end

    context 'when #requeue_message returns message' do
      before(:each) do
        expect(error_queue_handler).to receive(:requeue_message).with(serialized_message[:id]).and_return(serialized_message)
      end
      it { invoke_task(expected_stdout: output_format(serialized_message)) }
    end

    context 'when #requeue_message returns nil' do
      before(:each) do
        expect(error_queue_handler).to receive(:requeue_message).with(serialized_message[:id])
      end
      it { invoke_task(expected_stdout: /Message #{serialized_message[:id]} not found./) }
    end

    context 'when #requeue_message raises Bunny::Exception' do
      before(:each) do
        expect(error_queue_handler).to receive(:requeue_message).with(serialized_message[:id]).and_raise(Bunny::Exception)
      end
      it { invoke_task(expected_stderr: /An error occurred while requeueing message #{serialized_message[:id]}:/) }
      it { invoke_task(expected_stderr: /Bunny::Exception/) }
    end
  end
end

describe 'queue:errors:requeue_all' do
  include_context "rake"
  include_context 'error queue message utilities'
  let(:error_queue_handler) { instance_double(ErrorQueueHandler) }
  let(:serialized_messages) {[
    stub_message_response(Faker::Lorem.sentence, Faker::Internet.slug(nil, '_')),
    stub_message_response(Faker::Lorem.sentence, Faker::Internet.slug(nil, '_')),
    stub_message_response(Faker::Lorem.sentence, Faker::Internet.slug(nil, '_'))
  ]}
  def output_format(msg)
    /#{msg[:id]} \[#{msg[:routing_key]}\] "#{msg[:payload]}"/
  end

  before(:each) do
    expect(ErrorQueueHandler).to receive(:new).and_return(error_queue_handler)
  end

  context 'when #requeue_all returns messages' do
    before(:each) do
      expect(error_queue_handler).to receive(:requeue_all).and_return(serialized_messages)
    end
    it { invoke_task(expected_stdout: output_format(serialized_messages.first)) }
    it { invoke_task(expected_stdout: output_format(serialized_messages.second)) }
    it { invoke_task(expected_stdout: output_format(serialized_messages.third)) }
    it { invoke_task(expected_stdout: /#{serialized_messages.length} messages requeued./) }
  end

  context 'when #requeue_all returns an empty array' do
    before(:each) do
      expect(error_queue_handler).to receive(:requeue_all).and_return([])
    end
    it { invoke_task(expected_stdout: /0 messages requeued./) }
  end

  context 'when #requeue_all raises Bunny::Exception' do
    before(:each) do
      expect(error_queue_handler).to receive(:requeue_all).and_raise(Bunny::Exception)
    end
    it { invoke_task(expected_stderr: /An error occurred while requeueing messages:/) }
    it { invoke_task(expected_stderr: /Bunny::Exception/) }
  end
end

describe 'queue:errors:requeue_messages' do
  include_context "rake"
  include_context 'error queue message utilities'
  let(:error_queue_handler) { instance_double(ErrorQueueHandler) }
  let(:routing_key) { Faker::Internet.slug(nil, '_') }
  let(:serialized_messages) {[
    stub_message_response(Faker::Lorem.sentence, routing_key),
    stub_message_response(Faker::Lorem.sentence, routing_key),
    stub_message_response(Faker::Lorem.sentence, routing_key)
  ]}
  def output_format(msg)
    /#{msg[:id]} \[#{msg[:routing_key]}\] "#{msg[:payload]}"/
  end

  it { invoke_task(expected_stderr: /ROUTING_KEY required; set to routing key of messages to requeue./) }

  context 'with ROUTING_KEY' do
    include_context 'with env_override'
    let(:env_override) { {
      'ROUTING_KEY' => routing_key
    } }
    before(:each) do
      expect(ErrorQueueHandler).to receive(:new).and_return(error_queue_handler)
    end

    context 'when #requeue_messages returns messages' do
      before(:each) do
        expect(error_queue_handler).to receive(:requeue_messages).with(routing_key: routing_key, limit: nil).and_return(serialized_messages)
      end
      it { invoke_task(expected_stdout: output_format(serialized_messages.first)) }
      it { invoke_task(expected_stdout: output_format(serialized_messages.second)) }
      it { invoke_task(expected_stdout: output_format(serialized_messages.third)) }
      it { invoke_task(expected_stdout: /#{serialized_messages.length} messages requeued./) }
    end

    context 'when #requeue_messages returns an empty array' do
      before(:each) do
        expect(error_queue_handler).to receive(:requeue_messages).with(routing_key: routing_key, limit: nil).and_return([])
      end
      it { invoke_task(expected_stdout: /0 messages requeued./) }
    end

    context 'when #requeue_messages raises Bunny::Exception' do
      before(:each) do
        expect(error_queue_handler).to receive(:requeue_messages).with(routing_key: routing_key, limit: nil).and_raise(Bunny::Exception)
      end
      it { invoke_task(expected_stderr: /An error occurred while requeueing messages:/) }
      it { invoke_task(expected_stderr: /Bunny::Exception/) }
    end
  end

  context 'with ROUTING_KEY and LIMIT' do
    include_context 'with env_override'
    let(:limit) { serialized_messages.length }
    let(:env_override) { {
      'ROUTING_KEY' => routing_key,
      'LIMIT' => limit
    } }
    before(:each) do
      expect(ErrorQueueHandler).to receive(:new).and_return(error_queue_handler)
    end

    context 'when #requeue_messages returns messages' do
      before(:each) do
        expect(error_queue_handler).to receive(:requeue_messages).with(routing_key: routing_key, limit: limit).and_return(serialized_messages)
      end
      it { invoke_task(expected_stdout: output_format(serialized_messages.first)) }
      it { invoke_task(expected_stdout: output_format(serialized_messages.second)) }
      it { invoke_task(expected_stdout: output_format(serialized_messages.third)) }
      it { invoke_task(expected_stdout: /#{limit} messages requeued./) }
    end
  end
end

describe 'queue:message_log:index_messages' do
  include_context "rake"
  let(:message_log_queue_handler) { instance_double(MessageLogQueueHandler) }
  let(:routing_key) { Faker::Internet.slug(nil, '_') }
  let(:duration) { Faker::Number.between(1,300) }

  before(:each) do
    expect(MessageLogQueueHandler).to receive(:new).and_return(message_log_queue_handler)
    expect(message_log_queue_handler).to receive(:index_messages)
    allow(message_log_queue_handler).to receive(:work_duration).and_return(duration)
  end
  it { invoke_task(expected_stdout: /Indexing messages for #{duration} seconds/) }
end
