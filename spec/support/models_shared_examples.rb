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
    expect(KindnessFactory.is_kinded_model?(kinded_class)).to be_truthy
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
    is_expected.to allow_value(true).for(:is_deleted)
    is_expected.to allow_value(false).for(:is_deleted)
  end

  it_behaves_like 'an audited model'
  it_behaves_like 'a kind'

  it_behaves_like 'a logically deleted model'

  it_behaves_like 'a graphed relation' do
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
  self.use_transactional_tests = false
  let(:objects) { send(object_list) }
  after do
    ApplicationRecord.subclasses.each(&:delete_all)
  end
  before do
    expect(ApplicationRecord.connection.pool.size).to be > 4

    threads = objects.collect do |object|
      Thread.new do
        expect{object.send(method)}.not_to raise_error
      end
    end

    threads.each(&:join)
  end
end

shared_context 'trashed resource' do |resource_sym=nil|
  let(:resource_to_trash) { resource_sym.nil? ? subject : send(resource_sym) }
  before do
    resource_to_trash.move_to_trashbin
    expect(resource_to_trash.save).to be_truthy
  end
end

shared_examples 'an IdentityProvider' do
  it { is_expected.to be_an IdentityProvider }
  it { is_expected.to respond_to(:affiliates).with(0).arguments }
  it { is_expected.to respond_to(:affiliates).with_keywords(:full_name_contains) }
  it { is_expected.to respond_to(:affiliates).with_keywords(:username) }
  it { is_expected.to respond_to(:affiliates).with_keywords(:email) }

  it { is_expected.to respond_to(:affiliates_offset).with(0).arguments }
  it { is_expected.to respond_to(:affiliates_offset=).with(1).arguments }
  describe '#affiliates_offset attr_accessor' do
    let(:offset_value) { (1..100).to_a.sample }
    let(:set_affiliates_offset) { subject.affiliates_offset = offset_value }
    let(:get_affiliates_offset) { subject.affiliates_offset }
    it { expect(set_affiliates_offset).to eq offset_value }
    it { expect(get_affiliates_offset).to be_nil }

    context 'once set' do
      before(:example) { expect(set_affiliates_offset).to eq offset_value }
      it { expect(get_affiliates_offset).to eq offset_value }
    end
  end

  it { is_expected.to respond_to(:affiliates_limit).with(0).arguments }
  it { is_expected.to respond_to(:affiliates_limit=).with(1).arguments }
  describe '#affiliates_limit attr_accessor' do
    let(:limit_value) { (1..100).to_a.sample }
    let(:set_affiliates_limit) { subject.affiliates_limit = limit_value }
    let(:get_affiliates_limit) { subject.affiliates_limit }
    it { expect(set_affiliates_limit).to eq limit_value }
    it { expect(get_affiliates_limit).to be_nil }

    context 'once set' do
      before(:example) { expect(set_affiliates_limit).to eq limit_value }
      it { expect(get_affiliates_limit).to eq limit_value }
    end
  end

  it { is_expected.to respond_to(:affiliate).with(1).argument }
end
