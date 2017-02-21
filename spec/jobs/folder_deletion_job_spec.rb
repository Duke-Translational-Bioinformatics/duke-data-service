require 'rails_helper'

RSpec.describe FolderDeletionJob, type: :job do
  let(:folder) { FactoryGirl.create(:folder) }
  let(:prefix) { Rails.application.config.active_job.queue_name_prefix }
  let(:prefix_delimiter) { Rails.application.config.active_job.queue_name_delimiter }

  it { is_expected.to be_an ApplicationJob }
  it { expect(prefix).not_to be_nil }
  it { expect(prefix_delimiter).not_to be_nil }
  it { expect(described_class.queue_name).to eq("#{prefix}#{prefix_delimiter}folder_deletion") }

  context 'perform_now', :vcr do
    it 'should require a folder_id argument' do
      expect {
        described_class.perform_now
      }.to raise_error(ArgumentError)
    end

    it 'should ' do
      expect(folder.is_deleted?).to be_falsey
      described_class.perform_now(folder.id)
      folder.reload
      expect(folder.is_deleted?).to be_truthy
    end

    context 'with child folders' do
      let(:child_folder) { FactoryGirl.create(:folder, :with_parent) }
      let(:folder) { child_folder.parent }
      it {
        expect(folder).to be_persisted
        expect(child_folder).to be_persisted
        expect(folder.folder_ids).to include child_folder.id
        expect(described_class).to receive(:perform_later).with(child_folder.id)
        described_class.perform_now(folder.id)
      }
    end

    context 'with child files' do
      let(:child_file) { FactoryGirl.create(:data_file, :with_parent) }
      let(:folder) { child_file.parent }
      it {
        expect(child_file.is_deleted?).to be_falsey
        described_class.perform_now(folder.id)
        child_file.reload
        expect(child_file.is_deleted?).to be_truthy
      }
    end
  end
end
