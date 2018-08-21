shared_examples 'a parent project etag update' do |
    newly_created_object_sym,
    unchanged_object_sym,
    updated_object_sym,
    destroyed_object_sym
  |
  let(:newly_created_object) { send(newly_created_object_sym) }
  let(:unchanged_object) { send(unchanged_object_sym) }
  let(:updated_object) { send(updated_object_sym) }
  let(:destroyed_object) { send(destroyed_object_sym) }
  let(:project) { subject.project }

  it {
    is_expected.to callback(:update_project_etag).after(:save)
    is_expected.to callback(:update_project_etag).after(:destroy)
  }

  context 'after create' do
    subject { newly_created_object }
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

    context 'without change' do
      subject {
        unchanged_object
      }
      let!(:original_project_etag) { project.etag }
      let!(:original_project_audit) { project.audits.last }
      let!(:original_subject_last_audit) { subject.audits.last }
      it {
        expect(subject.save).to be_truthy
        project.reload
        expect(project.etag).to eq(original_project_etag)
        last_project_audit = project.audits.last
        expect(last_project_audit.comment).to eq(original_project_audit.comment)
        expect(last_project_audit.request_uuid).to eq(original_project_audit.request_uuid)
      }
    end

    context 'with change' do
      subject {
        updated_object
      }
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
  end

  context 'destroy' do
    subject {
      destroyed_object
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
