shared_examples 'an audited model' do
  let(:primary_key_column) { described_class.column_for_attribute(:id) }
  let(:audited_foriegn_key_column) { Audited.audit_class.column_for_attribute(:auditable_id) }

  it 'should have audit compatible primary key' do
    expect(primary_key_column.sql_type).to eq(audited_foriegn_key_column.sql_type)
  end
  it 'should have an audit record' do
    should have_many(:audits)
    expect(subject.audits).to be
  end
end

shared_examples 'an annotate_audits endpoint' do
  let(:expected_response_status) { 200 }
  let(:expected_audits) { 1 }
  let(:expected_auditable_type) { resource_class.base_class }
  let(:audit_should_include) { {user: current_user} }

  it 'should create expected audit types' do
    expect {
      is_expected.to eq(expected_response_status)
    }.to change{
      Audited.audit_class.where(
        auditable_type: expected_auditable_type.to_s
      ).count }.by(expected_audits)
  end

  it 'audit should record the remote address, uuid, endpoint action' do
    is_expected.to eq(expected_response_status)
    last_audit = Audited.audit_class.where(
      auditable_type: expected_auditable_type.to_s
    ).where(
      'comment @> ?', {action: called_action, endpoint: url}.to_json
    ).order(:created_at).last
    expect(last_audit.remote_address).to be_truthy
    expect(last_audit.request_uuid).to be_truthy
    expect(last_audit.comment).to have_key("endpoint")
    expect(last_audit.comment["endpoint"]).to be_truthy
    expect(last_audit.comment["endpoint"]).to eq(url)
    expect(last_audit.comment).to have_key("action")
    expect(last_audit.comment["action"]).to be_truthy
    expect(last_audit.comment["action"]).to eq(called_action)
  end

  it 'audit should include other expected attributes' do
    is_expected.to eq(expected_response_status)
    last_audit = Audited.audit_class.where(
      auditable_type: expected_auditable_type.to_s
    ).where(
      'comment @> ?', {action: called_action, endpoint: url}.to_json
    ).order(:created_at).last

    if audit_should_include[:user]
      user = audit_should_include[:user]
      expect(last_audit.user).to be
      expect(last_audit.user.id).to eq(user.id)
    end

    if audit_should_include[:software_agent]
      software_agent = audit_should_include[:software_agent]
      expect(last_audit.comment).to have_key("software_agent_id")
      expect(last_audit.comment["software_agent_id"]).to eq(software_agent.id)
    end

    if audit_should_include[:audited_parent]
      parent_audit = Audited.audit_class.where(
        auditable_type: audit_should_include[:audited_parent]
      ).where(
        'comment @> ?', {action: called_action, endpoint: url}.to_json
      ).order(:created_at).last
      audit_comment = parent_audit.comment
      expect(audit_comment).to have_key("raised_by_audit")
      expect(audit_comment["raised_by_audit"]).to be_truthy
      expect(audit_comment["raised_by_audit"]).to eq(last_audit.id)
      child_audit = Audited.audit_class.where(id: audit_comment['raised_by_audit']).take
      expect(child_audit).to be
      expect(child_audit.request_uuid).to eq(parent_audit.request_uuid)
    end
  end
end
