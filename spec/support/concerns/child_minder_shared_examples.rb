shared_context 'any ChildMinder' do |resource_factory,
  valid_child_file_sym,
  invalid_child_file_sym,
  child_folder_sym|
  let(:valid_child_file) { send(valid_child_file_sym) }
  let(:invalid_child_file) { send(invalid_child_file_sym) }
  let(:child_folder) { send(child_folder_sym) }

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

  describe '#purge_children' do
    it { is_expected.not_to respond_to(:purge_children).with(0).arguments }
    it { is_expected.to respond_to(:purge_children).with(1).argument }
    context 'called', :vcr do
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
end

shared_context 'common manage_children expectations' do
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
      expect(ChildPurgationJob).not_to receive(:perform_later)
      subject.manage_children do
        yield_called = true
      end
      expect(yield_called).to be_truthy
    }
  end
end

shared_examples 'a ChildMinder' do |resource_factory,
  valid_child_file_sym,
  invalid_child_file_sym,
  child_folder_sym|
  include_context 'with job runner', ChildPurgationJob
  include_context 'any ChildMinder', resource_factory, valid_child_file_sym, invalid_child_file_sym, child_folder_sym

  describe '#manage_children' do
    include_context 'common manage_children expectations'

    context 'when is_deleted changed from false to true' do
      context 'has_children? true' do
        let(:job_transaction) {
          subject.create_transaction('testing')
          ChildPurgationJob.initialize_job(subject)
        }
        before do
          @old_max = Rails.application.config.max_children_per_job
          Rails.application.config.max_children_per_job = 1
          expect(child_folder).to be_persisted
          expect(child_folder.is_deleted?).to be_falsey
          expect(valid_child_file).to be_persisted
          expect(valid_child_file.is_deleted?).to be_falsey
          expect(invalid_child_file).to be_persisted
          expect(invalid_child_file.is_deleted?).to be_falsey
        end

        after do
          Rails.application.config.max_children_per_job = @old_max
        end

        it {
          expect(subject).to be_has_children
          subject.is_deleted = true
          yield_called = false
          expect(ChildDeletionJob).not_to receive(:perform_later)
          expect(ChildPurgationJob).to receive(:initialize_job).exactly(subject.children.count)
            .with(subject).times.and_return(job_transaction)
          (1..subject.children.count).each do |page|
            expect(ChildPurgationJob).to receive(:perform_later).with(job_transaction, subject, page)
          end
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
          expect(ChildPurgationJob).not_to receive(:perform_later)
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
        is_expected.to be_persisted
        expect(subject.is_deleted?).to be_truthy
        is_expected.not_to allow_value(false).for(:is_deleted)
      }
    end

    context 'when something else changed' do
      it {
        subject.name = 'changed_name'
        expect(subject.is_deleted?).to be_falsey
        is_expected.to be_changed
        expect(subject.is_deleted_changed?).to be_falsey
        yield_called = false
        expect(ChildPurgationJob).not_to receive(:perform_later)
        subject.manage_children do
          yield_called = true
        end
        expect(yield_called).to be_truthy
      }
    end
  end
end

shared_examples 'a Trashable ChildMinder' do |resource_factory,
 valid_child_file_sym,
 invalid_child_file_sym,
 child_folder_sym|
 include_context 'with job runner', ChildDeletionJob
 include_context 'any ChildMinder', resource_factory, valid_child_file_sym, invalid_child_file_sym, child_folder_sym

 describe '#manage_children' do
   include_context 'common manage_children expectations'

   context 'when is_deleted, is_purged not changed' do
     it {
       expect(subject.is_deleted_changed?).to be_falsey
       expect(subject.is_purged_changed?).to be_falsey
       yield_called = false
       expect(ChildDeletionJob).not_to receive(:perform_later)
       expect(ChildRestorationJob).not_to receive(:perform_later)
       expect(ChildPurgationJob).not_to receive(:perform_later)
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
         @old_max = Rails.application.config.max_children_per_job
         Rails.application.config.max_children_per_job = 1
         expect(child_folder).to be_persisted
         expect(child_folder.is_deleted?).to be_falsey
         expect(valid_child_file).to be_persisted
         expect(valid_child_file.is_deleted?).to be_falsey
         expect(invalid_child_file).to be_persisted
         expect(invalid_child_file.is_deleted?).to be_falsey
       end

       after do
         Rails.application.config.max_children_per_job = @old_max
       end

       it {
         expect(subject).to be_has_children
         subject.is_deleted = true
         yield_called = false
         expect(ChildDeletionJob).to receive(:initialize_job).exactly(subject.children.count)
           .with(subject).times.and_return(job_transaction)
         (1..subject.children.count).each do |page|
           expect(ChildDeletionJob).to receive(:perform_later).with(job_transaction, subject, page)
         end
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
     context 'has_children? true' do
       let(:job_transaction) {
         subject.create_transaction('testing')
         ChildRestorationJob.initialize_job(subject)
       }
       before do
         @old_max = Rails.application.config.max_children_per_job
         Rails.application.config.max_children_per_job = 1
         subject.update_column(:is_deleted, true)
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
         expect(subject).to be_has_children
         subject.is_deleted = false
         yield_called = false
         expect(ChildRestorationJob).to receive(:initialize_job).exactly(subject.children.count)
           .with(subject).times.and_return(job_transaction)
         (1..subject.children.count).each do |page|
           expect(ChildRestorationJob).to receive(:perform_later).with(job_transaction, subject, page)
         end
         subject.manage_children do
           yield_called = true
         end
         expect(yield_called).to be_truthy
       }
     end

     context 'has_children? false' do
       subject { FactoryGirl.create(resource_factory, is_deleted: true) }
       it {
         expect(subject).not_to be_has_children
         subject.is_deleted = false
         yield_called = false
         expect(ChildRestorationJob).not_to receive(:perform_later)
         subject.manage_children do
           yield_called = true
         end
         expect(yield_called).to be_truthy
       }
     end
   end

   context 'when is_purged changed from false to true' do
     context 'has_children? true' do
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
         expect(subject).to be_has_children
         subject.is_purged = true
         yield_called = false
         expect(ChildPurgationJob).to receive(:initialize_job).exactly(subject.children.count)
           .with(subject).times.and_return(job_transaction)
         (1..subject.children.count).each do |page|
           expect(ChildPurgationJob).to receive(:perform_later).with(job_transaction, subject, page)
         end
         subject.manage_children do
           yield_called = true
         end
         expect(yield_called).to be_truthy
       }
     end

     context 'has_children? false' do
       subject { FactoryGirl.create(resource_factory, is_deleted: true) }
       it {
         expect(subject).not_to be_has_children
         subject.is_deleted = true
         yield_called = false
         expect(ChildPurgationJob).not_to receive(:perform_later)
         subject.manage_children do
           yield_called = true
         end
         expect(yield_called).to be_truthy
       }
     end
   end

   context 'when something else changed' do
     it {
       subject.name = 'changed_name'
       expect(subject.is_deleted?).to be_falsey
       expect(subject.is_purged?).to be_falsey
       is_expected.to be_changed
       expect(subject.is_deleted_changed?).to be_falsey
       expect(subject.is_purged?).to be_falsey
       yield_called = false
       expect(ChildDeletionJob).not_to receive(:perform_later)
       expect(ChildRestorationJob).not_to receive(:perform_later)
       expect(ChildPurgationJob).not_to receive(:perform_later)
       subject.manage_children do
         yield_called = true
       end
       expect(yield_called).to be_truthy
     }
   end
 end

 describe '#delete_children' do
   it { is_expected.not_to respond_to(:delete_children).with(0).arguments }
   it { is_expected.to respond_to(:delete_children).with(1).argument }

   context 'called', :vcr do
     let(:job_transaction) { ChildDeletionJob.initialize_job(subject) }
     let(:child_job_transaction) { ChildDeletionJob.initialize_job(child_folder) }
     let(:child_folder_file) { FactoryGirl.create(:data_file, parent: child_folder)}
     let(:page) { 1 }

     before do
       expect(child_folder).to be_persisted
       expect(child_folder_file).to be_persisted
       expect(valid_child_file.is_deleted?).to be_falsey
       @old_max = Rails.application.config.max_children_per_job
       Rails.application.config.max_children_per_job = subject.children.count + child_folder.children.count
     end

     after do
       Rails.application.config.max_children_per_job = @old_max
     end

     it {
       subject.current_transaction = job_transaction
       expect(ChildDeletionJob).to receive(:initialize_job)
         .with(child_folder)
         .and_return(child_job_transaction)
       expect(ChildDeletionJob).to receive(:perform_later)
         .with(child_job_transaction, child_folder, page).and_call_original
       subject.delete_children(page)
       expect(child_folder.reload).to be_truthy
       expect(child_folder.is_deleted?).to be_truthy
       expect(valid_child_file.reload).to be_truthy
       expect(valid_child_file.is_deleted?).to be_truthy
     }
   end
 end

 describe '#restore_children' do
   it { is_expected.not_to respond_to(:restore_children).with(0).arguments }
   it { is_expected.to respond_to(:restore_children).with(1).argument }

   context 'called', :vcr do
     let(:job_transaction) { ChildRestorationJob.initialize_job(subject) }
     let(:child_job_transaction) { ChildRestorationJob.initialize_job(child_folder) }
     let(:child_folder_file) { FactoryGirl.create(:data_file, parent: child_folder)}
     let(:page) { 1 }

     before do
       expect(child_folder).to be_persisted
       child_folder.update_column(:is_deleted, true)
       expect(child_folder_file).to be_persisted
       child_folder_file.update_column(:is_deleted, true)
       valid_child_file.update_column(:is_deleted, true)
       expect(valid_child_file.is_deleted?).to be_truthy

       @old_max = Rails.application.config.max_children_per_job
       Rails.application.config.max_children_per_job = subject.children.count + child_folder.children.count
     end

     after do
       Rails.application.config.max_children_per_job = @old_max
     end

     it {
       subject.current_transaction = job_transaction
       expect(ChildRestorationJob).to receive(:initialize_job)
         .with(child_folder)
         .and_return(child_job_transaction)
       expect(ChildRestorationJob).to receive(:perform_later)
         .with(child_job_transaction, child_folder, page).and_call_original
       subject.restore_children(page)
       expect(child_folder.reload).to be_truthy
       expect(child_folder.is_deleted?).to be_falsey
       expect(valid_child_file.reload).to be_truthy
       expect(valid_child_file.is_deleted?).to be_falsey
     }
   end
 end
end
