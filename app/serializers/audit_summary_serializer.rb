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
    creator = nil
    creation_agent_info = {}

    if creation_audit
      creator = User.where(id: creation_audit.user_id).first

      if creation_audit.comment && creation_audit.comment["software_agent_id"]
        creation_agent = SoftwareAgent.find(creation_audit.comment["software_agent_id"])
        creation_agent_info = {
          "agent": {
            "id": creation_agent.id,
            "name": creation_agent.name
          }
        }
      end
    end

    last_updator = nil
    last_update_agent_info = {}
    if last_update_audit
      last_updator = User.where(id: last_update_audit.user_id).first
      if last_update_audit.comment && last_update_audit.comment["software_agent_id"]
        last_update_agent = SoftwareAgent.find(last_update_audit.comment["software_agent_id"])
        last_update_agent_info = {
          "agent": {
            "id": last_update_agent.id,
            "name": last_update_agent.name
          }
        }
      end
    end

    deleter = nil
    deletion_agent_info = {}
    if delete_audit
      deleter = User.where(id: delete_audit.user_id).first
      if delete_audit.comment && delete_audit.comment["software_agent_id"]
        deletion_agent = SoftwareAgent.find(delete_audit.comment["software_agent_id"])
        deletion_agent_info = {
          "agent": {
            "id": deletion_agent.id,
            "name": deletion_agent.name
          }
        }
      end
    end

    {
      created_on: creation_audit ? creation_audit.created_at : nil,
      created_by: creator ? creator.audited_user_info.merge(creation_agent_info) : nil,
      last_updated_on: last_update_audit ? last_update_audit.created_at : nil,
      last_updated_by: last_updator ? last_updator.audited_user_info.merge(last_update_agent_info) : nil,
      deleted_on: delete_audit ? delete_audit.created_at : nil,
      deleted_by: deleter ? deleter.audited_user_info.merge(deletion_agent_info) : nil
    }
  end
end
