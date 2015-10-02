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
      subject.update_attributes!(update_attribute => update_value, :audit_comment => update_action)
    end
   }
end

shared_context 'with destroy' do
  include_context 'with auditor'
  let(:destroy_action) { '/destroy' }
  let(:delete) {
    Audited.audit_class.as_user(auditor) do
      subject.audit_comment = destroy_action
      subject.destroy
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
    expect(audit[:created_on].to_i).to eq(creation_audit.created_at.to_i)
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
    expect(audit[:last_updated_on].to_i).to eq(last_update_audit.created_at.to_i)
    updator = User.find(last_update_audit.user_id)
    expect(audit[:last_updated_by]).to eq({
      id: updator.id,
      username: updator.username,
      full_name: updator.display_name
    })

    expect(audit).to have_key(:deleted_on)
    expect(audit).to have_key(:deleted_by)
    delete_audit = subject.audits.where(action: "destroy").first
    expect(delete_audit).to be
    expect(audit[:deleted_on].to_i).to eq(delete_audit.created_at.to_i)
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

  it 'should create an audit with the current_user as user, and url as audit_comment' do
    expect(current_user).to be_persisted
    expect {
      is_expected.to eq(expected_status)
    }.to change{ Audited.audit_class.where(auditable_type: resource_class.to_s).count }.by(1)
    last_audit = Audited.audit_class.where(auditable_type: resource_class.to_s, comment: url).order(:created_at).last
    if with_current_user
      expect(last_audit.user).to be
      expect(last_audit.user.id).to eq(current_user.id)
    end
    expect(last_audit.comment).to eq(url)
  end

  it 'should create an audit for an audited_parent with the current_user as user, and url as audit_comment if with_audited_parent' do
    if with_audited_parent
      expect(current_user).to be_persisted
      expect {
        is_expected.to eq(expected_status)
      }.to change{ Audited.audit_class.where(auditable_type: resource_class.to_s).where("comment like ?", "#{url}%").count }.by(1)
      last_audit = Audited.audit_class.where(auditable_type: resource_class.to_s, comment: url).order(:created_at).last
      last_audit_parent_audit = with_audited_parent ? Audited.audit_class.where(auditable_type: with_audited_parent.to_s).where("comment like ?", "#{url}%").order(:created_at).last : nil
      if with_current_user
        expect(last_audit_parent_audit.user).to be
        expect(last_audit_parent_audit.user.id).to eq(current_user.id)
      end
      expect(last_audit_parent_audit.comment).to eq("#{url} raised by: #{ last_audit.id }")
    end
  end
end
