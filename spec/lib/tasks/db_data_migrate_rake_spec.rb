require 'rails_helper'

describe "db:data:migrate" do
  include_context "rake"
  let(:task_path) { "lib/tasks/db_data_migrate" }
  let(:current_user) { FactoryGirl.create(:user) }
  let(:file_version_audits) { Audited.audit_class.where(auditable: FileVersion.all) }
  let(:data_file_audits) { Audited.audit_class.where(auditable: DataFile.all) }

  it { expect(subject.prerequisites).to  include("environment") }

  describe "#invoke" do
    let(:invoke_task) { silence_stream(STDOUT) { subject.invoke } }

    context 'with current_file_versions to create' do
      before do
        Audited.audit_class.as_user(current_user) do
          FactoryGirl.create_list(:data_file, 3)
          FileVersion.last.destroy
          FileVersion.last.update_attribute(:upload, FactoryGirl.create(:upload, :completed))
          f = FactoryGirl.create(:data_file)
          f.upload = FactoryGirl.create(:upload, :completed)
          f.save
        end
      end

      it { expect(file_version_audits).to all(satisfy('have user set') {|v| v.user }) }
      it { expect(data_file_audits).to all(satisfy('have user set') {|v| v.user }) }
      it { expect {invoke_task}.to change{FileVersion.count}.by(2) }
      it { expect {invoke_task}.to change{Audited.audit_class.count}.by(2) }

      context 'once called' do
        before { invoke_task }

        it { expect(file_version_audits).to all(satisfy('have user set to current_user') {|v| v.user == current_user }) }
      end
    end

    context 'when creating fingerprints' do
      let(:fingerprint_upload) { FactoryGirl.create(:fingerprint).upload }
      let(:upload_with_fingerprint_value) { FactoryGirl.create(:upload, fingerprint_value: SecureRandom.hex, fingerprint_algorithm: 'md5') }
      let(:upload_with_invalid_fingerprint_algorithm) { FactoryGirl.create(:upload, fingerprint_value: SecureRandom.hex, fingerprint_algorithm: 'md5000') }
      context 'for upload without fingerprint_value' do
        before { FactoryGirl.create(:upload) }
        it { expect {invoke_task}.not_to change{Fingerprint.count} }
        it { expect {invoke_task}.not_to change{Audited.audit_class.count} }
      end
      context 'for upload with fingerprint_value' do
        before { expect(upload_with_fingerprint_value).to be_persisted }
        it { expect {invoke_task}.to change{Fingerprint.count}.by(1) }
        it { expect {invoke_task}.to change{Audited.audit_class.count}.by(1) }
      end
      context 'for upload with invalid fingerprint_algorithm' do
        before { expect(upload_with_invalid_fingerprint_algorithm).to be_persisted }
        it { expect {invoke_task}.to change{Fingerprint.count}.by(0) }
        it { expect {invoke_task}.to change{Audited.audit_class.count}.by(0) }
      end
      context 'for upload with associated fingerprint' do
        before { expect(fingerprint_upload).to be_persisted }
        it { expect {invoke_task}.not_to change{Fingerprint.count} }
        it { expect {invoke_task}.not_to change{Audited.audit_class.count} }
      end
      context 'for upload with associated fingerprint and fingerprint_value' do
        let(:fingerprint) { FactoryGirl.create(:fingerprint, upload: upload_with_fingerprint_value) }
        before { expect(fingerprint).to be_persisted }
        it { expect {invoke_task}.not_to change{Fingerprint.count} }
        it { expect {invoke_task}.not_to change{Audited.audit_class.count} }
      end
    end
  end
end
