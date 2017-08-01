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

    context 'perform_now', :vcr do
      let(:child_job_transaction) { described_class.initialize_job(child_folder) }
      let(:page) { 1 }
      include_context 'tracking job', :job_transaction

      before do
        @old_max = Rails.application.config.max_children_per_job
        Rails.application.config.max_children_per_job = parent.children.count + child_folder.children.count
      end

      after do
        Rails.application.config.max_children_per_job = @old_max
      end

      it {
        expect(child_folder).to be_persisted
        expect(child_file.is_deleted?).to be_falsey

        expect(described_class).to receive(:initialize_job)
          .with(child_folder)
          .and_return(child_job_transaction)
        expect(described_class).to receive(:perform_later)
          .with(child_job_transaction, child_folder, page).and_call_original

        described_class.perform_now(job_transaction, parent, page)
        expect(child_folder.reload).to be_truthy
        expect(child_folder.is_deleted?).to be_truthy
        expect(child_file.reload).to be_truthy
        expect(child_file.is_deleted?).to be_truthy
      }
    end
  end

  before do
    expect(folder_child).to be_persisted
  end
  context 'project' do
    let(:project) { FactoryGirl.create(:project) }
    let(:root_folder) { FactoryGirl.create(:folder, :root, project: project) }
    let(:folder_child) { FactoryGirl.create(:data_file, parent: root_folder) }
    let(:root_file) { FactoryGirl.create(:data_file, :root, project: project) }

    it_behaves_like 'a ChildDeletionJob', :project, :root_folder, :root_file
  end

  context 'folder' do
    let(:folder) { FactoryGirl.create(:folder) }
    let(:sub_folder) { FactoryGirl.create(:folder, parent: folder) }
    let(:folder_child) { FactoryGirl.create(:data_file, parent: sub_folder) }
    let(:sub_file) { FactoryGirl.create(:data_file, parent: folder) }

    it_behaves_like 'a ChildDeletionJob', :folder, :sub_folder, :sub_file
  end
end
