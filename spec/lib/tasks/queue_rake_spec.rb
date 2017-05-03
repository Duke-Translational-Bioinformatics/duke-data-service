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
