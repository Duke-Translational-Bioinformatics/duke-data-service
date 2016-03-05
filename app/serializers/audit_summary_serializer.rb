module AuditSummarySerializer
  def audit
    creation_audit = object.audits.where(action: "create").last
    last_update_audit = object.audits.where(action: "update").last
    delete_audit = nil
    if object.respond_to?('is_deleted') && object.is_deleted
      delete_audit = object.audits.where(action: "update").where(
        'comment @> ?', {action: 'DELETE'}.to_json
      ).last
    else
      delete_audit = object.audits.where(action: "destroy").last
    end
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
