shared_examples 'a Purgable' do
  it { expect(described_class).to include(Purgable) }

  describe 'callbacks' do
    it { is_expected.to callback(:manage_purgation).before(:update) }
  end

  describe 'validations' do
    before {
      subject.update_columns(is_deleted: true, is_purged: true)
    }
    it 'expects is_deleted and is_purged to be immutable once purged' do
      is_expected.to be_persisted
      expect(subject.is_deleted?).to be_truthy
      expect(subject.is_purged?).to be_truthy
      [:is_deleted, :is_purged].each do |immutable_field|
        is_expected.not_to allow_value(false).for(immutable_field)
      end
    end
  end

  describe '#can_be_purged' do
    context 'when is_deleted? false' do
      it {
        expect(subject.is_deleted).to be false
        is_expected.not_to allow_value(true).for(:is_purged)
      }
    end

    context 'when is_deleted? true' do
      before do
        subject.update_column(:is_deleted, true)
      end
      it {
        expect(subject.is_deleted).to be true
        is_expected.to allow_value(true).for(:is_purged)
      }
    end
  end
end

shared_examples 'a Purgable ChildMinder' do |resource_factory,
  valid_child_file_sym,
  invalid_child_file_sym,
  child_folder_sym|
  let(:valid_child_file) { send(valid_child_file_sym) }
  let(:invalid_child_file) { send(invalid_child_file_sym) }
  let(:child_folder) { send(child_folder_sym) }

  it_behaves_like 'a Purgable'
  it_behaves_like 'a ChildMinder', resource_factory, valid_child_file_sym, invalid_child_file_sym, child_folder_sym

  describe '#purge_children' do
    it { is_expected.not_to respond_to(:purge_children).with(0).arguments }
    it { is_expected.to respond_to(:purge_children).with(1).argument }
    context 'called', :vcr do
      include_context 'with job runner', ChildPurgationJob
      let(:job_transaction) { ChildPurgationJob.initialize_job(subject) }
      let(:child_job_transaction) { ChildPurgationJob.initialize_job(child_folder) }
      let(:child_folder_file) { FactoryGirl.create(:data_file, parent: child_folder)}
      let(:page) { 1 }

      before do
        expect(child_folder).to be_persisted
        expect(child_folder_file).to be_persisted
        @old_max = Rails.application.config.max_children_per_job
        Rails.application.config.max_children_per_job = subject.children.count + child_folder.children.count
      end

      after do
        Rails.application.config.max_children_per_job = @old_max
      end

      it {
        expect(child_folder.is_deleted?).to be_falsey
        expect(child_folder.is_purged?).to be_falsey
        expect(valid_child_file.is_deleted?).to be_falsey
        expect(valid_child_file.is_purged?).to be_falsey
        subject.current_transaction = job_transaction
        expect(ChildPurgationJob).to receive(:initialize_job)
          .with(child_folder)
          .and_return(child_job_transaction)
        expect(ChildPurgationJob).to receive(:perform_later)
          .with(child_job_transaction, child_folder, page).and_call_original
        subject.purge_children(page)
        expect(child_folder.reload).to be_truthy
        expect(child_folder.is_deleted?).to be_truthy
        expect(child_folder.is_purged?).to be_truthy
        expect(valid_child_file.reload).to be_truthy
        expect(valid_child_file.is_deleted?).to be_truthy
        expect(valid_child_file.is_purged?).to be_truthy
      }
    end
  end

  describe '#manage_children' do
    context 'when is_purged not changed' do
      it {
        expect(subject.is_purged_changed?).to be_falsey
        subject.manage_purgation
        expect(ChildPurgationJob).not_to receive(:perform_later)
        subject.manage_children
      }
    end

    context 'when is_purged changed from false to true' do
      context 'has_children? true' do
        include_context 'with job runner', ChildPurgationJob
        let(:job_transaction) {
          subject.create_transaction('testing')
          ChildPurgationJob.initialize_job(subject)
        }
        before do
          @old_max = Rails.application.config.max_children_per_job
          Rails.application.config.max_children_per_job = 1
          expect(child_folder).to be_persisted
          child_folder.update_column(:is_deleted, true)
          expect(child_folder.is_deleted?).to be_truthy
          expect(valid_child_file).to be_persisted
          valid_child_file.update_column(:is_deleted, true)
          expect(valid_child_file.is_deleted?).to be_truthy
          expect(invalid_child_file).to be_persisted
          invalid_child_file.update_column(:is_deleted, true)
          expect(invalid_child_file.is_deleted?).to be_truthy
        end

        after do
          Rails.application.config.max_children_per_job = @old_max
        end

        it {
          expect(subject.has_children?).to be_truthy
          subject.is_purged = true
          subject.manage_purgation
          expect(ChildPurgationJob).to receive(:initialize_job)
            .with(subject)
            .exactly(subject.children.count).times
            .and_return(job_transaction)
          (1..subject.children.count).each do |page|
            expect(ChildPurgationJob).to receive(:perform_later).with(job_transaction, subject, page)
          end
          subject.manage_children
        }
      end

      context 'has_children? false' do
        subject { FactoryGirl.create(resource_factory, is_deleted: true) }
        it {
          expect(subject.has_children?).to be_falsey
          subject.is_deleted = true
          subject.manage_purgation
          expect(ChildPurgationJob).not_to receive(:perform_later)
          subject.manage_children
        }
      end
    end

    context 'when is_purged not changed' do
      it {
        subject.name = 'changed_name'
        expect(subject.is_purged?).to be_falsey
        is_expected.to be_changed
        expect(subject.is_purged?).to be_falsey
        subject.manage_purgation
        expect(ChildPurgationJob).not_to receive(:perform_later)
        subject.manage_children
      }
    end
  end #manage_children
end
