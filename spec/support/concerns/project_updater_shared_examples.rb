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
    let(:audit_comment) { nil }

    before do
      subject.audit_comment = audit_comment
      expect(create_subject).to be_truthy
      expect(change_subject).to be_truthy
      subject.update_project_etag
      project.reload
      subject.reload
    end

    it {
      expect(project.etag).not_to eq(original_project_etag)
    }

    context 'with audit comment' do
      let(:last_project_audit) { project.audits.last }
      let(:last_subject_audit) { subject.audits.last }

      context 'present' do
        let(:audit_comment) {{"foo" => "bar"}}
        let(:expected_comment) { audit_comment.merge({raised_by_audit: last_subject_audit.id}) }
        it {
          expect(last_project_audit.comment.symbolize_keys).to eq(expected_comment.symbolize_keys)
          expect(last_project_audit.request_uuid).to eq(last_subject_audit.request_uuid)
        }
      end

      context 'absent' do
        let(:expected_comment) { {raised_by_audit: last_subject_audit.id} }
        it {
          expect(last_project_audit.comment.symbolize_keys).to eq(expected_comment)
          expect(last_project_audit.request_uuid).to eq(last_subject_audit.request_uuid)
        }
      end
    end
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
        expect(subject.changed?).to be_falsey
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
