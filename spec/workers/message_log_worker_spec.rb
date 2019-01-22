require 'rails_helper'

RSpec.describe MessageLogWorker do
  let(:gateway_exchange_name) { Sneakers::CONFIG[:exchange] }
  let(:queue_name) { 'message_log' }
  let(:error_exchange) { "#{queue_name}-error" }

  it { expect(described_class).to include(Sneakers::Worker) }
  it { expect(subject.queue.name).to eq(queue_name) }
  it { expect(subject.opts[:exchange]).to eq(gateway_exchange_name) }
  it { expect(subject.opts[:exchange_options][:type]).to eq(:fanout) }
  it { expect(subject.opts[:exchange_options][:durable]).to be_truthy }
  it { expect(subject.opts[:exchange_options][:durable]).to be_truthy }
  it { expect(subject.opts[:retry_error_exchange]).to eq(error_exchange) }

  it { is_expected.not_to respond_to(:work) }
  it { is_expected.to respond_to(:work_with_params).with(3).arguments }

  describe '#work_with_params' do
    include_context 'with env_override'
    let(:message) { {job_info: Faker::Lorem.words(5)} }
    let(:routing_key) { Faker::Internet.slug }
    let(:delivery_info) { expected_delivery_info }
    let(:expected_delivery_info) { {
      exchange: Faker::Internet.slug,
      routing_key: routing_key,
      delivery_tag: Faker::Number.digit
    } }
    let(:metadata) {{
      content_type: Faker::File.mime_type,
      delivery_mode: Faker::Number.digit,
      priority: Faker::Number.digit
    }}
    let(:index_name) { 'queue_messages' }
    let(:log_message) {{
      'message' => {
        'payload' => message.to_json,
        'delivery_info' => expected_delivery_info.to_json,
        'properties' => metadata.to_json
      }
    }}
    let(:method) { subject.work_with_params(message, delivery_info, metadata) }
    let(:ack) { subject.ack! }
    it { expect(ack).not_to be_nil }

    it_behaves_like 'an elasticsearch indexer' do
      include_context 'with a single document indexed'
      before(:each) do
        elasticsearch_client.indices.delete index: '_all'
        expect(method).to eq ack
      end

      let(:expected_settings) {{"number_of_replicas" => "0"}}
      let(:index_settings) { elasticsearch_client.indices.get_settings[index_name]["settings"]["index"] }

      it { expect(index_settings).to include(expected_settings) }
      it { expect(document["_index"]).to eq(index_name) }
      it { expect(document["_type"]).to eq(routing_key) }
      it { expect(document["_source"]).to eq(log_message) }

      context 'with extra delivery_info' do
        let(:delivery_info) { expected_delivery_info.merge({connection: 'x'}) }

        it { expect(document["_source"]).to eq(log_message) }
      end

      context 'with env MESSAGE_LOG_WORKER_INDEXING_DISABLED set' do
        let(:env_override) { {
          'MESSAGE_LOG_WORKER_INDEXING_DISABLED' => 'yes'
        } }
        it { expect(new_documents).to be_empty }
      end
    end
  end
end
