require 'rails_helper'

describe 'queue:message_log:index_messages' do
  include_context "rake"
  let(:message_log_queue_handler) { instance_double(MessageLogQueueHandler) }
  let(:routing_key) { Faker::Internet.slug(words: nil, glue: '_') }
  let(:duration) { Faker::Number.between(from: 1, to: 300) }
  let(:expected_output) { /Indexing messages for #{duration} seconds/ }

  before(:each) do
    expect(MessageLogQueueHandler).to receive(:new).and_return(message_log_queue_handler)
    expect(message_log_queue_handler).to receive(:index_messages)
    allow(message_log_queue_handler).to receive(:work_duration).and_return(duration)
  end
  it { invoke_task(expected_stdout: expected_output) }

  context 'without MESSAGE_LOG_WORK_DURATION' do
    before(:each) do
      expect(ENV['MESSAGE_LOG_WORK_DURATION']).to be_nil
      expect(message_log_queue_handler).not_to receive(:work_duration=)
    end
    it { invoke_task(expected_stdout: expected_output) }
  end

  context 'with MESSAGE_LOG_WORK_DURATION' do
    include_context 'with env_override'
    let(:env_override) { {
      'MESSAGE_LOG_WORK_DURATION' => duration
    } }
    before(:each) { expect(message_log_queue_handler).to receive(:work_duration=).with(duration) }
    it { invoke_task(expected_stdout: expected_output) }
  end
end
