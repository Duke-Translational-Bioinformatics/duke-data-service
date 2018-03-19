require 'rails_helper'

RSpec.describe ProjectContainerElasticsearchUpdateJob, type: :job do

  it { expect(described_class.should_be_registered_worker?).to be_truthy }

  shared_examples 'a ProjectContainerElasticsearchUpdateJob' do |
      parent_sym,
      child_folder_sym,
      child_file_sym
    |
    let(:parent) { send(parent_sym) }
    let(:job_transaction) { described_class.initialize_job(parent) }
    let(:child_folder) { send(child_folder_sym) }
    let(:child_file) { send(child_file_sym) }
    let(:prefix) { Rails.application.config.active_job.queue_name_prefix }
    let(:prefix_delimiter) { Rails.application.config.active_job.queue_name_delimiter }
    include_context 'with job runner', described_class

    it { is_expected.to be_an ApplicationJob }
    it { expect(prefix).not_to be_nil }
    it { expect(prefix_delimiter).not_to be_nil }
    it { expect(described_class.queue_name).to eq("#{prefix}#{prefix_delimiter}project_container_elasticsearch_update") }
    it {
      expect {
        described_class.perform_now
      }.to raise_error(ArgumentError)
      expect {
        described_class.perform_now(job_transaction)
      }.to raise_error(ArgumentError)
      expect {
        described_class.perform_now(job_transaction, parent)
      }.to raise_error(ArgumentError)
    }

    context 'perform_now' do
      let(:page) { 1 }

      it {
        expect(child_folder).to be_persisted
        expect(child_file).to be_persisted
        expect(parent).to receive(:update_container_elasticsearch_index_project).with(page)
        described_class.perform_now(job_transaction, parent, page)
      }
    end
  end

  context 'project' do
    let(:project) { FactoryBot.create(:project) }
    let(:root_folder) { FactoryBot.create(:folder, :root, project: project) }
    let(:folder_child) { FactoryBot.create(:data_file, parent: root_folder, project: project) }
    let(:root_file) { FactoryBot.create(:data_file, :root, project: project) }

    before do
      expect(folder_child).to be_persisted
    end

    it_behaves_like 'a ProjectContainerElasticsearchUpdateJob', :project, :root_folder, :root_file
  end
end
