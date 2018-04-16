require 'rails_helper'

RSpec.describe ElasticsearchIndexJob, type: :job do
  let(:prefix) { Rails.application.config.active_job.queue_name_prefix }
  let(:prefix_delimiter) { Rails.application.config.active_job.queue_name_delimiter }
  it { is_expected.to be_an ApplicationJob }
  it { expect(prefix).not_to be_nil }
  it { expect(prefix_delimiter).not_to be_nil }
  it { expect(described_class.queue_name).to eq("#{prefix}#{prefix_delimiter}elasticsearch_index") }

  it { expect(described_class.should_be_registered_worker?).to be_truthy }

  context 'data_file' do
    it_behaves_like 'an ElasticsearchIndexJob', :data_file
  end

  context 'folder' do
    it_behaves_like 'an ElasticsearchIndexJob', :folder
  end
end
