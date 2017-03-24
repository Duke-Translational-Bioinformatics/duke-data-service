shared_examples 'a ChildMinder' do |resource_factory,
  valid_child_file_sym,
  invalid_child_file_sym,
  child_folder_sym|
  let(:valid_child_file) { send(valid_child_file_sym) }
  let(:invalid_child_file) { send(invalid_child_file_sym) }
  let(:child_folder) { send(child_folder_sym) }
  include_context 'with job runner', ChildDeletionJob

  before {
    ActiveJob::Base.queue_adapter = :test
  }

  it {
    expect(described_class).to include(ChildMinder)
    is_expected.to respond_to(:children)
  }

  describe '#has_children?' do
    it { is_expected.to respond_to(:has_children?) }

    context 'without children' do
      subject { FactoryGirl.create(resource_factory) }
      it { expect(subject.children.count).to eq(0) }
      it { expect(subject.has_children?).to be_falsey }
    end

    context 'with children' do
      before do
        expect(child_folder).to be_persisted
        expect(child_folder.is_deleted?).to be_falsey
        expect(valid_child_file).to be_persisted
        expect(valid_child_file.is_deleted?).to be_falsey
        expect(invalid_child_file).to be_persisted
        expect(invalid_child_file.is_deleted?).to be_falsey
      end
      it { expect(subject.children.count).to be > 0 }
      it { expect(subject.has_children?).to be_truthy }
    end
  end

  describe '#manage_children' do
    it {
      is_expected.to respond_to(:manage_children)
    }

    describe 'callbacks' do
      it {
        is_expected.to callback(:manage_children).around(:update)
      }
    end

    context 'when is_deleted not changed' do
      it {
        expect(subject.is_deleted_changed?).to be_falsey
        yield_called = false
        expect(ChildDeletionJob).not_to receive(:perform_later)
        subject.manage_children do
          yield_called = true
        end
        expect(yield_called).to be_truthy
      }
    end

    context 'when is_deleted changed from false to true' do
      context 'has_children? true' do
        let(:job_transaction) {
          subject.create_transaction('testing')
          ChildDeletionJob.initialize_job(subject)
        }
        before do
          expect(child_folder).to be_persisted
          expect(child_folder.is_deleted?).to be_falsey
          expect(valid_child_file).to be_persisted
          expect(valid_child_file.is_deleted?).to be_falsey
          expect(invalid_child_file).to be_persisted
          expect(invalid_child_file.is_deleted?).to be_falsey
        end
        
        it {
          expect(subject).to be_has_children
          subject.is_deleted = true
          yield_called = false
          expect(ChildDeletionJob).to receive(:initialize_job)
            .with(subject).and_return(job_transaction)
          expect(ChildDeletionJob).to receive(:perform_later).with(job_transaction, subject)
          subject.manage_children do
            yield_called = true
          end
          expect(yield_called).to be_truthy
        }
      end

      context 'has_children? false' do
        subject { FactoryGirl.create(resource_factory) }
        it {
          expect(subject).not_to be_has_children
          subject.is_deleted = true
          yield_called = false
          expect(ChildDeletionJob).not_to receive(:perform_later)
          subject.manage_children do
            yield_called = true
          end
          expect(yield_called).to be_truthy
        }
      end
    end

    context 'when is_deleted changed from true to false' do
      subject { FactoryGirl.create(resource_factory, is_deleted: true) }
      it {
        expect(subject.is_deleted?).to be_truthy
        subject.is_deleted = false
        yield_called = false
        expect(ChildDeletionJob).not_to receive(:perform_later)
        subject.manage_children do
          yield_called = true
        end
        expect(yield_called).to be_truthy
      }
    end

    context 'when something else changed' do
      it {
        subject.name = 'changed_name'
        expect(subject.is_deleted?).to be_falsey
        is_expected.to be_changed
        expect(subject.is_deleted_changed?).to be_falsey
        yield_called = false
        expect(ChildDeletionJob).not_to receive(:perform_later)
        subject.manage_children do
          yield_called = true
        end
        expect(yield_called).to be_truthy
      }
    end
  end

  describe '#delete_children' do
    it {
      is_expected.to respond_to(:delete_children)
    }
    it {
      expect(child_folder).to be_persisted
      expect(child_folder.is_deleted?).to be_falsey
      expect(valid_child_file).to be_persisted
      expect(valid_child_file.is_deleted?).to be_falsey
      expect(invalid_child_file).to be_persisted
      expect(invalid_child_file.is_deleted?).to be_falsey
      subject.delete_children
      expect(child_folder.reload).to be_truthy
      expect(child_folder.is_deleted?).to be_truthy
      valid_child_file.reload
      expect(valid_child_file.is_deleted?).to be_truthy
      invalid_child_file.reload
      expect(invalid_child_file.is_deleted?).to be_truthy
    }
  end
end
