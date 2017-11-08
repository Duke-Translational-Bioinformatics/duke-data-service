require 'rails_helper'

RSpec.describe ChildPurgationJob, type: :job do

  it { expect(described_class.should_be_registered_worker?).to be_truthy }

  shared_examples 'a ChildPurgationJob' do |
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
    it { expect(described_class.queue_name).to eq("#{prefix}#{prefix_delimiter}child_purgation") }
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
        expect(child_folder.is_deleted?).to be_truthy
        expect(child_file).to be_persisted
        expect(child_file.is_deleted?).to be_truthy
        expect(parent).to receive(:purge_children).with(page)
        described_class.perform_now(job_transaction, parent, page)
      }
    end
  end

  context 'project' do
    let(:project) { FactoryGirl.create(:project, is_deleted: true) }
    let(:root_folder) { FactoryGirl.create(:folder, :root, project: project, is_deleted: true) }
    let(:folder_child) { FactoryGirl.create(:data_file, parent: root_folder, is_deleted: true) }
    let(:root_file) { FactoryGirl.create(:data_file, :root, project: project, is_deleted: true) }

    before do
      expect(folder_child).to be_persisted
      expect(folder_child.is_deleted?).to be_truthy
    end

    it_behaves_like 'a ChildPurgationJob', :project, :root_folder, :root_file
  end

  context 'folder' do
    let(:folder) { FactoryGirl.create(:folder, is_deleted: true) }
    let(:sub_folder) { FactoryGirl.create(:folder, parent: folder, is_deleted: true) }
    let(:folder_child) { FactoryGirl.create(:data_file, parent: sub_folder, is_deleted: true) }
    let(:sub_file) { FactoryGirl.create(:data_file, parent: folder, is_deleted: true) }

    before do
      expect(folder_child).to be_persisted
      expect(folder_child.is_deleted?).to be_truthy
    end

    it_behaves_like 'a ChildPurgationJob', :folder, :sub_folder, :sub_file
  end
end
