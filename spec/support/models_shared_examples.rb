shared_examples 'a kind' do
  let(:resource_serializer) { ActiveModel::Serializer.serializer_for(subject) }

  it 'should have a kind' do
    expect(subject).to respond_to('kind')
    expect(subject.kind).to eq(expected_kind)
  end

  it 'should serialize the kind' do
    if serialized_kind
      serializer = resource_serializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to have_key('kind')
      expect(parsed_json["kind"]).to eq(expected_kind)
    end
  end

  it 'should be registered in KindnessFactory.kinded_models' do
    expect(KindnessFactory.kinded_models).to include(kinded_class)
  end

  it 'should be returned by KindnessFactory.by_kind(expected_kind)' do
    expect(KindnessFactory.by_kind(expected_kind)).to eq(kinded_class)
  end
end

shared_examples 'a ProvRelation' do
  let(:expected_kind) { ['dds', subject.class.name].join('-') }
  let(:serialized_kind) { true }
  let(:kinded_class) { subject.class }

  describe 'validations' do
    let(:deleted_copy) {
      described_class.new(
          is_deleted: true,
          creator_id: subject.creator.id,
          relatable_from: subject.relatable_from,
          relatable_to: subject.relatable_to
      )
    }
    let(:invalid_copy) {
      described_class.new(
          creator_id: subject.creator.id,
          relatable_from: subject.relatable_from,
          relatable_to: subject.relatable_to
      )
    }

    it { is_expected.to validate_presence_of :creator_id }
    it { is_expected.to validate_presence_of :relatable_from }
    it { is_expected.to validate_presence_of :relatable_to }
    it 'should be unique to all but deleted ProvRelations' do
      expect(deleted_copy).to be_valid
      expect(deleted_copy.save).to be true
      is_expected.to be_persisted
      expect(invalid_copy).not_to be_valid
    end
  end

  it 'should implement set_relationship_type' do
    is_expected.to respond_to(:set_relationship_type)
    subject.relationship_type = nil
    expect{
      subject.set_relationship_type
    }.to_not raise_error
    expect(subject.relationship_type).to be
  end

  it 'should allow is_deleted to be set' do
    should allow_value(true).for(:is_deleted)
    should allow_value(false).for(:is_deleted)
  end

  it_behaves_like 'an audited model'
  it_behaves_like 'a kind'

  it_behaves_like 'a logically deleted model'

  it_behaves_like 'a graphed relation', auto_create: true do
    let(:from_model) { subject.relatable_from }
    let(:to_model) { subject.relatable_to }
    let(:rel_type) { subject.relationship_type.split('-').map{|part| part.capitalize}.join('') }
  end

  it 'should set the relationship_type automatically' do
    built_relation = described_class.new(
      creator: subject.creator,
      relatable_from: subject.relatable_from,
      relatable_to: subject.relatable_to
    )
    built_relation.save
    expect(built_relation.relationship_type).to eq(expected_relationship_type)

    created_relation = described_class.create(
      creator: subject.creator,
      relatable_from: subject.relatable_from,
      relatable_to: subject.relatable_to
    )
    expect(created_relation.relationship_type).to eq(expected_relationship_type)
  end
end

shared_examples 'a logically deleted model' do
  it { is_expected.to respond_to :is_deleted }

  # if this fails, ensure that the default value for is_deleted
  # in the migration creating the model is false, e.g.
  # t.boolean :is_deleted, :default => false
  it 'should ensure is_deleted is false even if not specified in create' do
    expect(described_class.column_defaults['is_deleted']).not_to be_nil
  end
end

shared_context 'with concurrent calls' do |object_list:, method:|
  self.use_transactional_fixtures = false
  let(:objects) { send(object_list) }
  after do
    ActiveRecord::Base.subclasses.each(&:delete_all)
  end
  before do
    expect(ActiveRecord::Base.connection.pool.size).to be > 4

    threads = objects.collect do |object|
      Thread.new do
        expect{object.send(method)}.not_to raise_error
      end
    end

    threads.each(&:join)
  end
end

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
      let(:job_transaction) {
        subject.create_transaction('testing')
        ChildDeletionJob.initialize_job(subject)
      }
      it {
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
