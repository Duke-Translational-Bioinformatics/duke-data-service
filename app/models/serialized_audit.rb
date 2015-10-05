module SerializedAudit
  def audit
    creation_audit = audits.where(action: "create").last
    last_update_audit = audits.where(action: "update").last
    delete_audit = audits.where(action: "destroy").last
    creator = creation_audit ?
        User.where(id: creation_audit.user_id).first :
        nil
    last_updator = last_update_audit ?
        User.where(id: last_update_audit.user_id).first :
        nil
    deleter = delete_audit ?
        User.where(id: delete_audit.user_id).first :
        nil
    {
      created_on: creation_audit ? creation_audit.created_at : nil,
      created_by: creator ? creator.audited_user_info : nil,
      last_updated_on: last_update_audit ? last_update_audit.created_at : nil,
      last_updated_by: last_updator ? last_updator.audited_user_info : nil,
      deleted_on: delete_audit ? delete_audit.created_at : nil,
      deleted_by: deleter ? deleter.audited_user_info : nil
    }
  end
end
