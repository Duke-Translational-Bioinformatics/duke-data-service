require 'rails_helper'

describe "db:data:migrate" do
  include_context "rake"
  let(:task_path) { "lib/tasks/db_data_migrate" }
  let(:current_user) { FactoryGirl.create(:user) }
  let(:file_version_audits) { Audited.audit_class.where(auditable: FileVersion.all) }
  let(:data_file_audits) { Audited.audit_class.where(auditable: DataFile.all) }

  before do
    Audited.audit_class.as_user(current_user) do
      FactoryGirl.create_list(:data_file, 4)
      FileVersion.last.destroy
      FileVersion.last.update_attribute(:upload, FactoryGirl.create(:upload, :completed))
      f = FactoryGirl.create(:data_file)
      f.upload = FactoryGirl.create(:upload, :completed)
      f.save
    end
  end

  it { expect(subject.prerequisites).to  include("environment") }

  describe "#invoke" do
    let(:invoke_task) { silence_stream(STDOUT) { subject.invoke } }

    it { expect(file_version_audits).to all(satisfy('have user set') {|v| v.user }) }
    it { expect(data_file_audits).to all(satisfy('have user set') {|v| v.user }) }
    it { expect {invoke_task}.to change{FileVersion.count}.by(2) }
    it { expect {invoke_task}.to change{Audited.audit_class.count}.by(2) }

    context 'once called' do
      before { invoke_task }

      it { expect(file_version_audits).to all(satisfy('have user set to current_user') {|v| v.user == current_user }) }
    end
  end
end
