require 'rails_helper'

RSpec.describe ProjectPermission, type: :model do
  subject {FactoryBot.build(:project_permission)}
  let(:project) { subject.project }

  it_behaves_like 'an audited model'

  describe 'associations' do
    it 'should belong to a user' do
      should belong_to :user
    end

    it 'should belong to a project' do
      should belong_to :project
    end

    it 'should have many a project permissions' do
      should have_many(:project_permissions).through(:project)
    end

    it 'should belong to an auth_role' do
      should belong_to :auth_role
    end
  end

  describe 'validations' do
    it 'should have a user_id' do
      should validate_presence_of(:user_id)
    end

    it 'should have a user_id unique to the project' do
      should validate_uniqueness_of(:user_id).scoped_to(:project_id).case_insensitive
    end

    it 'should have a project_id' do
      should validate_presence_of(:project_id)
    end

    it 'should have an auth_role_id' do
      should validate_presence_of(:auth_role_id)
    end
  end

  describe '#update_project_etag' do
    it {
      is_expected.to callback(:update_project_etag).after(:save)
      is_expected.to callback(:update_project_etag).after(:destroy)
    }

    context 'after create' do
      subject { FactoryBot.build(:project_permission, :project_admin) }
      let!(:original_project_etag) { project.etag }

      it {
        expect(subject.save).to be_truthy
        project.reload
        subject.reload
        last_project_audit = project.audits.last
        last_subject_audit = subject.audits.last
        expect(project.etag).not_to eq(original_project_etag)

        expected_comment = last_subject_audit.comment ? last_subject_audit.comment.merge({raised_by_audit: last_subject_audit.id}) : {raised_by_audit: last_subject_audit.id}
        expect(last_project_audit.comment.symbolize_keys).to eq(expected_comment)

        expect(last_project_audit.request_uuid).to eq(last_subject_audit.request_uuid)
      }
    end

    context 'after update' do
      let(:user) { FactoryBot.create(:user) }
      subject {
        FactoryBot.create(:project_permission, :project_admin, user: user)
      }

      context 'without auth_role change' do
        let!(:auth_role) { subject.auth_role }
        let!(:original_project_etag) { project.etag }
        let!(:original_project_audit) { project.audits.last }
        let!(:original_subject_last_audit) { subject.audits.last }
        it {
          subject.auth_role = auth_role
          expect(subject.save).to be_truthy
          project.reload
          expect(project.etag).to eq(original_project_etag)
          last_project_audit = project.audits.last
          expect(last_project_audit.comment).to eq(original_project_audit.comment)
          expect(last_project_audit.request_uuid).to eq(original_project_audit.request_uuid)
        }
      end

      context 'with auth_role change' do
        let(:auth_role) { FactoryBot.create(:auth_role, :project_viewer) }
        let!(:original_project_etag) { project.etag }
        it {
          subject.auth_role = auth_role
          expect(subject.save).to be_truthy
          project.reload
          subject.reload
          last_project_audit = project.audits.last
          last_subject_audit = subject.audits.last
          expect(project.etag).not_to eq(original_project_etag)

          expected_comment = last_subject_audit.comment ? last_subject_audit.comment.merge({raised_by_audit: last_subject_audit.id}) : {raised_by_audit: last_subject_audit.id}
          expect(last_project_audit.comment.symbolize_keys).to eq(expected_comment)

          expect(last_project_audit.request_uuid).to eq(last_subject_audit.request_uuid)
        }
      end
    end

    context 'destroy' do
      subject {
        FactoryBot.create(:project_permission, :project_admin)
      }
      let!(:original_project_etag) { project.etag }
      it {
        expect(subject.audits.count).to be > 0
        expect(subject.destroy).to be_truthy
        project.reload
        last_project_audit = project.audits.last
        last_subject_audit = subject.audits.last
        expect(project.etag).not_to eq(original_project_etag)

        expected_comment = last_subject_audit.comment ? last_subject_audit.comment.merge({raised_by_audit: last_subject_audit.id}) : {raised_by_audit: last_subject_audit.id}
        expect(last_project_audit.comment.symbolize_keys).to eq(expected_comment)

        expect(last_project_audit.request_uuid).to eq(last_subject_audit.request_uuid)
      }
    end
  end
end
