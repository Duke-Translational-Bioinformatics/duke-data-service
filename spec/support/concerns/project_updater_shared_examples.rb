shared_examples 'a ProjectUpdater' do
  let(:project) { subject.project }
  let(:create_subject) {
    subject.save
    subject.reload
  }

  it {
    is_expected.to respond_to(:update_project_etag)
    is_expected.to callback(:update_project_etag).after(:save)
    is_expected.to callback(:update_project_etag).after(:destroy)
  }

  describe '#update_project_etag' do
    let!(:original_project_etag) { project.etag }
    it {
      expect(create_subject).to be_truthy
      expect(change_subject).to be_truthy
      subject.update_project_etag
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

  context 'after create' do
    it {
      is_expected.not_to be_persisted
      is_expected.to receive(:update_project_etag)
      expect(subject.save).to be_truthy
    }
  end

  context 'after update' do
    before do
      expect(create_subject).to be_truthy
    end

    context 'without change' do
      it {
        is_expected.not_to receive(:update_project_etag)
        expect(subject.saved_changes?).to be_falsey
        expect(subject.save).to be_truthy
      }
    end

    context 'with change' do
      it {
        is_expected.to receive(:update_project_etag)
        expect(change_subject).to be_truthy
        expect(subject.changed?).to be_truthy
        expect(subject.save).to be_truthy
      }
    end
  end

  context 'destroy' do
    it {
      expect(create_subject).to be_truthy
      is_expected.to receive(:update_project_etag)
      expect(subject.destroy).to be_truthy
    }
  end
end
