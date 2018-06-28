shared_examples 'a Restorable' do
  it { expect(described_class).to include(Restorable) }
  it { is_expected.to respond_to :manage_deletion_and_restoration }
  describe 'callbacks' do
    it { is_expected.to callback(:manage_deletion_and_restoration).before(:update) }
  end
end

shared_examples 'a Restorable ChildMinder' do |resource_factory,
  expected_children_sym,
  child_minder_children_sym=nil|
  let(:expected_children) { send(expected_children_sym) }
  if child_minder_children_sym
    let(:child_minder_children) {
      send(child_minder_children_sym)
    }
  else
    let(:child_minder_children) {[]}
  end

  it_behaves_like 'a Restorable'
  it_behaves_like 'a ChildMinder', resource_factory, expected_children_sym

  it { is_expected.not_to respond_to(:delete_children).with(0).arguments }
  it { is_expected.to respond_to(:delete_children).with(1).argument }
  it { is_expected.not_to respond_to(:restore_children).with(0).arguments }
  it { is_expected.to respond_to(:restore_children).with(1).argument }

  describe '#manage_children' do
    context 'when is_deleted not changed' do
      it {
        expect(subject.is_deleted_changed?).to be_falsey
        subject.manage_deletion_and_restoration
        expect(ChildDeletionJob).not_to receive(:perform_later)
        expect(ChildRestorationJob).not_to receive(:perform_later)
        subject.manage_children
      }
    end

    context 'when is_deleted changed from false to true' do
      include_context 'with job runner', ChildDeletionJob
      context 'has_children? true' do
        let(:job_transaction) {
          subject.create_transaction('testing')
          ChildDeletionJob.initialize_job(subject)
        }
        before do
          @old_max = Rails.application.config.max_children_per_job
          Rails.application.config.max_children_per_job = 1
          expect(expected_children).not_to be_empty
          expected_children.each do |expected_child|
            expect(expected_child).to be_persisted
          end
        end

        after do
          Rails.application.config.max_children_per_job = @old_max
        end

        it {
          expect(subject.has_children?).to be_truthy
          subject.is_deleted = true
          subject.manage_deletion_and_restoration
          expect(ChildDeletionJob).to receive(:initialize_job)
            .with(subject)
            .exactly(subject.children.count).times
            .and_return(job_transaction)
          (1..subject.children.count).each do |page|
            expect(ChildDeletionJob).to receive(:perform_later)
            .with(job_transaction, subject, page)
          end
          subject.manage_children
        }
      end

      context 'has_children? false' do
        subject { FactoryBot.create(resource_factory, is_deleted: true) }
        before do
          subject.children.delete_all
        end
        it {
          expect(subject.has_children?).to be_falsey
          subject.is_deleted = true
          subject.manage_deletion_and_restoration
          expect(ChildDeletionJob).not_to receive(:perform_later)
          subject.manage_children
        }
      end
    end

    context 'when is_deleted changed from true to false' do
      context 'has_children? true' do
        include_context 'with job runner', ChildRestorationJob
        let(:job_transaction) {
          subject.create_transaction('testing')
          ChildRestorationJob.initialize_job(subject)
        }
        before do
          @old_max = Rails.application.config.max_children_per_job
          Rails.application.config.max_children_per_job = 1
          subject.update_column(:is_deleted, true)
          expect(expected_children).not_to be_empty
          expected_children.each do |expected_child|
            expect(expected_child).to be_persisted
            expected_child.update_column(:is_deleted, true)
            expect(expected_child.is_deleted?).to be_truthy
          end
        end

        after do
          Rails.application.config.max_children_per_job = @old_max
        end

        it {
          expect(subject).to be_has_children
          subject.is_deleted = false
          subject.manage_deletion_and_restoration
          expect(ChildRestorationJob).to receive(:initialize_job)
            .with(subject)
            .exactly(subject.children.count).times
            .and_return(job_transaction)
          (1..subject.children.count).each do |page|
            expect(ChildRestorationJob).to receive(:perform_later).with(job_transaction, subject, page)
          end
          subject.manage_children
        }
      end

      context 'has_children? false' do
        subject { FactoryBot.create(resource_factory, is_deleted: true) }
        before do
          subject.children.delete_all
        end
        it {
          expect(subject).not_to be_has_children
          subject.is_deleted = false
          subject.manage_deletion_and_restoration
          expect(ChildRestorationJob).not_to receive(:perform_later)
          subject.manage_children
        }
      end
    end
  end #manage_children

  describe '#restore_children' do
    include_context 'with job runner', ChildRestorationJob
    let(:job_transaction) { ChildRestorationJob.initialize_job(subject) }
    if child_minder_children_sym
      let(:child_job_transaction) { ChildRestorationJob.initialize_job(child_minder_children.first) }
    end

    let(:page) { 1 }

    before do
      expect(expected_children).not_to be_empty
      expected_children.each do |expected_child|
        expect(expected_child).to be_persisted
        expected_child.update_column(:is_deleted, true)
      end
      @old_max = Rails.application.config.max_children_per_job
      Rails.application.config.max_children_per_job = subject.children.count
    end

    after do
      Rails.application.config.max_children_per_job = @old_max
    end

    it {
      subject.current_transaction = job_transaction
      expected_children.each do |cmc|
        expect(cmc.is_deleted?).to be_truthy
      end
      child_minder_children.each do |cmc|
        expect(ChildRestorationJob).to receive(:initialize_job)
          .with(cmc)
          .and_return(child_job_transaction)
        expect(ChildRestorationJob).to receive(:perform_later)
          .with(child_job_transaction, cmc, page).and_call_original
      end
      subject.restore_children(page)
      subject.children.each do |cmc|
        cmc.reload
        expect(cmc.is_deleted?).to be_falsey
      end
    }
  end #restore_children

  describe '#delete_children' do
    include_context 'with job runner', ChildDeletionJob
    let(:job_transaction) { ChildDeletionJob.initialize_job(subject) }
    if child_minder_children_sym
      let(:child_job_transaction) { ChildDeletionJob.initialize_job(child_minder_children.first) }
    end
    let(:page) { 1 }

    before do
      subject.update_columns(is_deleted: true)
      expect(expected_children).not_to be_empty
      expected_children.each do |expected_child|
        expect(expected_child).to be_persisted
      end
      @old_max = Rails.application.config.max_children_per_job
      Rails.application.config.max_children_per_job = subject.children.count
    end

    after do
      Rails.application.config.max_children_per_job = @old_max
    end

    it {
      subject.current_transaction = job_transaction
      expected_children.each do |cmc|
        expect(cmc.is_deleted?).to be_falsey
        expect(cmc.is_purged?).to be_falsey
      end
      child_minder_children.each do |cmc|
        expect(ChildDeletionJob).to receive(:initialize_job)
          .with(cmc)
          .and_return(child_job_transaction)
        expect(ChildDeletionJob).to receive(:perform_later)
          .with(child_job_transaction, cmc, page).and_call_original
      end
      subject.delete_children(page)
      expected_children.each do |cmc|
        cmc.reload
        expect(cmc.is_deleted?).to be_truthy
        expect(cmc.is_purged?).to be_falsey
      end
    }
  end #delete_children
end
