module AuditSummarySerializer
  def audit
    audit_summary = {
    }
    object.audits.each do |audit|
      if audit[:action] == "create"
        audit_summary[:created_on] = audit.created_at
        audit_summary[:created_by] = audit_user_info_hash(audit)
      elsif audit[:action] == "update"
        audit_summary[:last_updated_on] = audit.created_at
        audit_summary[:last_updated_by] = audit_user_info_hash(audit)

        if audit&.comment&.fetch('action', nil) == 'DELETE' &&
            audit&.audited_changes&.fetch('is_deleted', [true,false])[1]
          audit_summary[:deleted_on] = audit.created_at
          audit_summary[:deleted_by] = audit_user_info_hash(audit)
        end

        if audit&.comment&.fetch('endpoint', '').match(/\/restore$/) &&
            !audit&.audited_changes&.fetch('is_deleted', [true,true])[1]
          audit_summary[:restored_on] = audit.created_at
          audit_summary[:restored_by] = audit_user_info_hash(audit)
        end

        if audit&.comment&.fetch('endpoint', '').match(/\/purge$/) &&
            audit&.audited_changes&.fetch('is_purged', [true,false])[1]
          audit_summary[:purged_on] = audit.created_at
          audit_summary[:purged_by] = audit_user_info_hash(audit)
        end

      elsif audit[:action] == "destroy"
        audit_summary[:deleted_on] = audit.created_at
        audit_summary[:deleted_by] = audit_user_info_hash(audit)
      end
    end

    {
      created_on: nil,
      created_by: nil,
      last_updated_on: nil,
      last_updated_by: nil,
      deleted_on: nil,
      deleted_by: nil
    }.merge(audit_summary)
  end

private

  def audit_user_info_hash(audit)
    user_info = nil
    if audit.user
      user_info = audit.user.audited_user_info
      if audit&.comment&.has_key?("software_agent_id")
        creation_agent = SoftwareAgent.find(audit.comment["software_agent_id"])
        user_info.merge!(
          {
            "agent": {
              "id": creation_agent.id,
              "name": creation_agent.name
            }
          }
        )
      end
    end
    user_info
  end
end
