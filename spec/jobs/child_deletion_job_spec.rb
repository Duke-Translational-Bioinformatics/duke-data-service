require 'rails_helper'

RSpec.describe ChildDeletionJob, type: :job do

  shared_examples 'a ChildDeletionJob' do |
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
    it { expect(described_class.queue_name).to eq("#{prefix}#{prefix_delimiter}child_deletion") }
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
        expect(parent).to receive(:delete_children).with(page)
        described_class.perform_now(job_transaction, parent, page)
      }
    end
  end

  before do
    expect(folder_child).to be_persisted
  end
  context 'project' do
    let(:project) { FactoryBot.create(:project) }
    let(:root_folder) { FactoryBot.create(:folder, :root, project: project) }
    let(:folder_child) { FactoryBot.create(:data_file, parent: root_folder) }
    let(:root_file) { FactoryBot.create(:data_file, :root, project: project) }

    it_behaves_like 'a ChildDeletionJob', :project, :root_folder, :root_file
  end

  context 'folder' do
    let(:folder) { FactoryBot.create(:folder) }
    let(:sub_folder) { FactoryBot.create(:folder, parent: folder) }
    let(:folder_child) { FactoryBot.create(:data_file, parent: sub_folder) }
    let(:sub_file) { FactoryBot.create(:data_file, parent: folder) }

    it_behaves_like 'a ChildDeletionJob', :folder, :sub_folder, :sub_file
  end
end
