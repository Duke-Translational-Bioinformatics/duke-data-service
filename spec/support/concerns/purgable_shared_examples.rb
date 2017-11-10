shared_examples 'a Purgable' do
  it { expect(described_class).to include(Purgable) }
  it {
    is_expected.to respond_to :purge
  }

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

  it_behaves_like 'a Purgable'
  it_behaves_like 'a ChildMinder', resource_factory, expected_children_sym

  it { is_expected.not_to respond_to(:purge_children).with(0).arguments }
  it { is_expected.to respond_to(:purge_children).with(1).argument }

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
          expect(subject.has_children?).to be_truthy
          subject.is_purged = true
          subject.manage_purgation
          expect(ChildPurgationJob).to receive(:initialize_job)
            .with(subject)
            .exactly(subject.children.count).times
            .and_return(job_transaction)
          (1..subject.children.count).each do |page|
            expect(ChildPurgationJob).to receive(:perform_later)
            .with(job_transaction, subject, page)
          end
          subject.manage_children
        }
      end

      context 'has_children? false' do
        subject { FactoryGirl.create(resource_factory, is_deleted: true) }
        before do
          subject.children.delete_all
        end
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

  describe '#purge_children' do
    include_context 'with job runner', ChildPurgationJob
    let(:job_transaction) { ChildPurgationJob.initialize_job(subject) }
    if child_minder_children_sym
      let(:child_job_transaction) { ChildPurgationJob.initialize_job(child_minder_children.first) }
    end
    let(:page) { 1 }

    before do
      subject.update_columns(is_deleted: true, is_purged: true)
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
      expected_children.each do |expected_child|
        expect(expected_child.is_deleted?).to be_falsey
        expect(expected_child.is_purged?).to be_falsey
      end
      subject.current_transaction = job_transaction

      child_minder_children.each do |cmc|
        expect(ChildPurgationJob).to receive(:initialize_job)
          .with(cmc)
          .and_return(child_job_transaction)
        expect(ChildPurgationJob).to receive(:perform_later)
          .with(child_job_transaction, cmc, page).and_call_original
      end
      subject.purge_children(page)

      expected_children.each do |expected_child|
        expect(expected_child.reload).to be_truthy
        expect(expected_child.is_deleted?).to be_truthy
        expect(expected_child.is_purged?).to be_truthy
      end
    }
  end #purge_children
end
