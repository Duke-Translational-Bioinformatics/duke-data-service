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

  before do
    expect(ErrorQueueHandler).to receive(:new).and_return(error_queue_handler)
    expect(error_queue_handler).to receive(:messages).and_return(serialized_messages)
  end
  it { invoke_task(expected_stdout: output_format(serialized_messages.first)) }
  it { invoke_task(expected_stdout: output_format(serialized_messages.second)) }
  it { invoke_task(expected_stdout: output_format(serialized_messages.third)) }
end
