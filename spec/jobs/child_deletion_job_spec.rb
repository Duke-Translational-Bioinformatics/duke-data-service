require 'rails_helper'

RSpec.describe ChildDeletionJob, type: :job do

  it { expect(described_class.should_be_registered_worker?).to be_truthy }

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
      let(:current_user) { FactoryBot.create(:user) }
      let(:current_remote_address) { Faker::Internet.ip_v4_address }
      let(:current_comment) { {
        'endpoint' => Faker::Internet.url,
        'action' => 'GET'
      } }
      let(:deletion_request_uuid) { ApplicationAudit.generate_current_request_uuid }
      before(:each) do
        ApplicationAudit.current_user = current_user
        ApplicationAudit.current_remote_address = current_remote_address
        ApplicationAudit.current_comment = current_comment
        expect(deletion_request_uuid).not_to be_nil
        expect(child_folder).to be_persisted
        expect(child_file).to be_persisted
        expect(parent.root_destroy_transaction).not_to be_nil
        ApplicationAudit.clear_store
        expect(job_transaction.request_id).to eq deletion_request_uuid
      end

      it 'calls .start_job and parent#delete_children in order' do
        expect(described_class).to receive(:start_job).with(job_transaction).ordered
        expect(parent).to receive(:delete_children).with(page).ordered
        described_class.perform_now(job_transaction, parent, page)
      end

      it 'calls parent#current_transaction= and parent#delete_children in order' do
        expect(parent).to receive(:current_transaction=).with(job_transaction).ordered
        expect(parent).to receive(:delete_children).with(page).ordered
        described_class.perform_now(job_transaction, parent, page)
      end

      it 'calls parent#delete_children and .complete_job in order' do
        expect(parent).to receive(:delete_children).with(page).ordered
        expect(described_class).to receive(:complete_job).with(job_transaction).ordered
        described_class.perform_now(job_transaction, parent, page)
      end

      it 'creates audits with deletion_request_uuid' do
        expect {
          described_class.perform_now(job_transaction, parent, page)
        }.to change{Audited.audit_class.where(request_uuid: deletion_request_uuid).count}
      end

      it 'creates audits with current_user' do
        expect {
          described_class.perform_now(job_transaction, parent, page)
        }.to change{Audited.audit_class.where(user: current_user).count}
      end

      it 'creates audits with current_remote_address' do
        expect {
          described_class.perform_now(job_transaction, parent, page)
        }.to change{Audited.audit_class.where(remote_address: current_remote_address).count}
      end

      it 'creates audits with current_comment' do
        expect {
          described_class.perform_now(job_transaction, parent, page)
        }.to change{Audited.audit_class.where(comment: current_comment).count}
      end
    end
  end

  context 'folder' do
    let(:folder) { FactoryBot.create(:folder) }
    let(:sub_folder) { FactoryBot.create(:folder, parent: folder) }
    let(:folder_child) { FactoryBot.create(:data_file, parent: sub_folder) }
    let(:sub_file) { FactoryBot.create(:data_file, parent: folder) }

    before do
      expect(folder_child).to be_persisted
    end
    it_behaves_like 'a ChildDeletionJob', :folder, :sub_folder, :sub_file
  end
end
