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
      subject.update_attributes!(update_attribute => update_value, :audit_comment => {"action": update_action})
    end
   }
end

shared_context 'with destroy' do
  include_context 'with auditor'
  let(:destroy_action) { '/destroy' }
  let(:delete) {
    Audited.audit_class.as_user(auditor) do
      subject.audit_comment = {"action": destroy_action}
      if is_logically_deleted
        subject.update(is_deleted: true)
        subject.audits.last.update(comment: {action: 'DELETE'})
      else
        subject.destroy
      end
    end
  }
end

shared_examples 'an audited model' do
  it 'should have an audit record' do
    expect(subject.audits).to be
  end
end

shared_examples 'with a serialized audit' do
  include_context 'with update'
  include_context 'with destroy'
  let(:resource_serializer) { ActiveModel::Serializer.serializer_for(subject) }

  it 'should have an audit method that returns the audit expected by the serializer' do
    expect(update).to be_truthy
    expect(delete).to be_truthy
    expect(subject).to respond_to( 'audit' )
    audit = subject.audit
    expect(audit).to be
    expect(audit).to have_key(:created_on)
    expect(audit).to have_key(:created_by)
    creation_audit = subject.audits.where(action: "create").first
    expect(creation_audit).to be
    expect(audit[:created_on].to_i).to be_within(1).of(creation_audit.created_at.to_i)
    if creation_audit.user_id
      creator = User.find(creation_audit.user_id)
      expect(audit[:created_by]).to eq({
        id: creator.id,
        username: creator.username,
        full_name: creator.display_name
      })
    else
      expect(audit[:created_by]).not_to be
    end

    expect(audit).to have_key(:last_updated_on)
    expect(audit).to have_key(:last_updated_by)
    last_update_audit = subject.audits.where(action: "update").last
    expect(last_update_audit).to be
    expect(audit[:last_updated_on].to_i).to be_within(1).of(last_update_audit.created_at.to_i)
    updator = User.find(last_update_audit.user_id)
    expect(audit[:last_updated_by]).to eq({
      id: updator.id,
      username: updator.username,
      full_name: updator.display_name
    })

    expect(audit).to have_key(:deleted_on)
    expect(audit).to have_key(:deleted_by)
    delete_audit = is_logically_deleted ?
      subject.audits.where(action: "update").where('comment @> ?', {action: 'DELETE'}.to_json).first :
      subject.audits.where(action: "destroy").first
    expect(delete_audit).to be
    expect(audit[:deleted_on].to_i).to be_within(1).of(delete_audit.created_at.to_i)
    deleter = User.find(delete_audit.user_id)
    expect(audit[:deleted_by]).to eq({
      id: deleter.id,
      username: deleter.username,
      full_name: deleter.display_name
    })
  end

  it 'should serialize with an audit' do
    expect(update).to be_truthy
    expect(delete).to be_truthy
    serializer = resource_serializer.new subject
    payload = serializer.to_json
    expect(payload).to be
    parsed_json = JSON.parse(payload)
    expect(parsed_json).to have_key('audit')
    expect(parsed_json['audit'].to_json).to eq(subject.audit.to_json)
  end
end

shared_examples 'an audited endpoint' do
  let(:expected_status) { 200 }
  let(:with_current_user) { true }
  let(:with_audited_parent) { false }
  let(:expected_audits) { 1 }
  let(:expected_auditable_type) { resource_class.base_class.to_s }

  it 'should create an audit with the current_user as user, and url as audit_comment' do
    expect {
      is_expected.to eq(expected_status)
    }.to change{
      Audited.audit_class.where(
        auditable_type: expected_auditable_type
      ).where(
        'comment @> ?', {action: called_action, endpoint: url}.to_json
      ).count }.by(expected_audits)
    last_audit = Audited.audit_class.where(
      auditable_type: expected_auditable_type
    ).where(
      'comment @> ?', {action: called_action, endpoint: url}.to_json
    ).order(:created_at).last
    if with_current_user
      expect(last_audit.user).to be
      expect(last_audit.user.id).to eq(current_user.id)
    end
    expect(last_audit.remote_address).to be_truthy
    expect(last_audit.request_uuid).to be_truthy
    expect(last_audit.comment).to have_key("endpoint")
    expect(last_audit.comment["endpoint"]).to be_truthy
    expect(last_audit.comment["endpoint"]).to eq(url)
    expect(last_audit.comment).to have_key("action")
    expect(last_audit.comment["action"]).to be_truthy
    expect(last_audit.comment["action"]).to eq(called_action)
  end

  it 'should create an audit for an audited_parent with the current_user as user, and url as audit_comment if with_audited_parent' do
    if with_audited_parent
      expect(current_user).to be_persisted
      expect {
        is_expected.to eq(expected_status)
      }.to change{
        Audited.audit_class.where(
          auditable_type: expected_auditable_type
          ).where(
            'comment @> ?', {action: called_action, endpoint: url}.to_json
          ).count
      }.by(1)
      last_audit = Audited.audit_class.where(
        auditable_type: expected_auditable_type
      ).where(
        'comment @> ?', {action: called_action, endpoint: url}.to_json
      ).order(:created_at).last
      last_audit_parent_audit = Audited.audit_class.where(
        auditable_type: with_audited_parent.to_s
      ).where(
        'comment @> ?', {action: called_action, endpoint: url}.to_json
      ).order(:created_at).last
      if with_current_user
        expect(last_audit_parent_audit.user).to be
        expect(last_audit_parent_audit.user.id).to eq(current_user.id)
      end
      expect(last_audit.request_uuid).to be_truthy
      expect(last_audit_parent_audit.request_uuid).to be_truthy
      expect(last_audit.remote_address).to be_truthy
      expect(last_audit_parent_audit.remote_address).to be_truthy
      expect(last_audit_parent_audit.remote_address).to eq(last_audit.remote_address)
      expect(last_audit_parent_audit.request_uuid).to eq(last_audit.request_uuid)
      audit_comment = last_audit_parent_audit.comment
      expect(audit_comment).to have_key("endpoint")
      expect(audit_comment).to have_key("action")
      expect(audit_comment).to have_key("raised_by_audit")
      expect(audit_comment["endpoint"]).to be_truthy
      expect(audit_comment["endpoint"]).to eq(url)
      expect(audit_comment["action"]).to be_truthy
      expect(audit_comment["action"]).to eq(called_action)
      expect(audit_comment["raised_by_audit"]).to be_truthy
      expect(audit_comment["raised_by_audit"]).to eq(last_audit.id)
    end
  end
end
