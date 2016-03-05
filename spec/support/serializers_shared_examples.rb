shared_context 'with auditor' do
  let(:auditor) { FactoryGirl.create(:user) }
end

shared_context 'with update' do
  include_context 'with auditor'
  let(:update_attribute) { 'updated_at' }
  let(:update_value) { DateTime.now }
  let(:update_action) { '/update' }
  let(:update) {
    Audited.audit_class.as_user(auditor) do
      resource.update_attributes!(update_attribute => update_value, :audit_comment => {"action": update_action})
    end
   }
end

shared_context 'with destroy' do
  include_context 'with auditor'
  let(:destroy_action) { '/destroy' }
  let(:delete) {
    Audited.audit_class.as_user(auditor) do
      resource.audit_comment = {"action": destroy_action}
      if is_logically_deleted
        resource.update(is_deleted: true)
        resource.audits.last.update(comment: {action: 'DELETE'})
      else
        resource.destroy
      end
    end
  }
end

shared_examples 'a json serializer' do
  let(:serializer) { described_class.new resource }
  subject { JSON.parse(serializer.to_json) }

  it 'should serialize to json' do
    expect{subject}.to_not raise_error
  end
end

shared_examples 'a serializer with a serialized audit' do
  # YOU MUST RUN THIS WITHIN A 'a json serializer' shared example block
  it 'should serialize with an audit' do
    is_expected.to have_key('audit')
    audit = subject['audit']
    expect(audit).to be
  end

  it 'should report created_by and created_on' do
    is_expected.to have_key('audit')
    audit = subject['audit']
    expect(audit).to have_key("created_on")
    expect(audit).to have_key("created_by")
    creation_audit = resource.audits.where(action: "create").first
    expect(creation_audit).to be
    expect(DateTime.parse(audit["created_on"]).to_i).to be_within(1).of(creation_audit.created_at.to_i)
    if creation_audit.user_id
      creator = User.find(creation_audit.user_id)
      expect(audit["created_by"]).to eq({
        id: creator.id,
        username: creator.username,
        full_name: creator.display_name
      })
    else
      expect(audit["created_by"]).not_to be
    end
  end

  context 'for an updated resource' do
    include_context 'with update'
    before do
      expect(update).to be_truthy
    end

    it 'should report last_updated_on and last_updated_by' do
      is_expected.to have_key('audit')
      audit = subject['audit']
      expect(audit).to have_key("last_updated_on")
      expect(audit).to have_key("last_updated_by")
      last_update_audit = resource.audits.where(action: "update").last
      expect(last_update_audit).to be
      expect(DateTime.parse(audit["last_updated_on"]).to_i).to be_within(1).of(last_update_audit.created_at.to_i)
      updator = User.find(last_update_audit.user_id)
      expect(audit["last_updated_by"]).to eq({
        "id" => updator.id,
        "username" => updator.username,
        "full_name" => updator.display_name
      })
    end
  end

  context 'for a deleted resource' do
    include_context 'with destroy'
    before do
      expect(delete).to be_truthy
    end

    it 'should report deleted_on and deleted_by' do
      is_expected.to have_key('audit')
      audit = subject['audit']
      expect(audit).to have_key("deleted_on")
      expect(audit).to have_key("deleted_by")
      delete_audit = is_logically_deleted ?
        resource.audits.where(action: "update").where('comment @> ?', {action: 'DELETE'}.to_json).first :
        resource.audits.where(action: "destroy").first
      expect(delete_audit).to be
      expect(DateTime.parse(audit["deleted_on"]).to_i).to be_within(1).of(delete_audit.created_at.to_i)
      deleter = User.find(delete_audit.user_id)
      expect(audit["deleted_by"]).to eq({
        "id" => deleter.id,
        "username" => deleter.username,
        "full_name" => deleter.display_name
      })
    end
  end
end

shared_examples 'a has_one association with' do |association_root, serialized_with|
  it "#{association_root} serialized using #{serialized_with}" do
    expect(described_class._associations).to have_key(association_root)
    expect(described_class._associations[association_root]).to be_a(ActiveModel::Serializer::Association::HasOne)
    expect(described_class._associations[association_root].serializer_from_options).to eq(serialized_with)
  end
end

shared_examples 'a has_many association with' do |association_root, serialized_with|
  it "#{association_root} serialized using #{serialized_with}" do
    expect(described_class._associations).to have_key(association_root)
    expect(described_class._associations[association_root]).to be_a(ActiveModel::Serializer::Association::HasMany)
    expect(described_class._associations[association_root].serializer_from_options).to eq(serialized_with)
  end
end
