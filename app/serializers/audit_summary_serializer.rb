module AuditSummarySerializer
  def audit
    audit_summary = {
    }
    object.audits.each do |audit|
      if audit[:action] == "create"
        audit_summary[:created_on] = audit.created_at
        if audit.user
          audit_summary[:created_by] = audit.user.audited_user_info
          if audit&.comment&.has_key?("software_agent_id")
            creation_agent = SoftwareAgent.find(audit.comment["software_agent_id"])
            audit_summary[:created_by].merge!(
              {
                "agent": {
                  "id": creation_agent.id,
                  "name": creation_agent.name
                }
              }
            )
          end
        end
      elsif audit[:action] == "update"
        audit_summary[:last_updated_on] = audit.created_at
        if audit.user
          audit_summary[:last_updated_by] = audit.user.audited_user_info
          if audit&.comment&.has_key?("software_agent_id")
            creation_agent = SoftwareAgent.find(audit.comment["software_agent_id"])
            audit_summary[:last_updated_by].merge!(
              {
                "agent": {
                  "id": creation_agent.id,
                  "name": creation_agent.name
                }
              }
            )
          end
        end
        if audit&.comment["action"] == 'DELETE' && 
            object.respond_to?('is_deleted') && object.is_deleted
          audit_summary[:deleted_on] = audit.created_at
          if audit.user
            audit_summary[:deleted_by] = audit.user.audited_user_info
            if audit&.comment&.has_key?("software_agent_id")
              creation_agent = SoftwareAgent.find(audit.comment["software_agent_id"])
              audit_summary[:deleted_by].merge!(
                {
                  "agent": {
                    "id": creation_agent.id,
                    "name": creation_agent.name
                  }
                }
              )
            end
          end
        end
      elsif audit[:action] == "destroy"
        audit_summary[:deleted_on] = audit.created_at
        if audit.user
          audit_summary[:deleted_by] = audit.user.audited_user_info
          if audit&.comment&.has_key?("software_agent_id")
            creation_agent = SoftwareAgent.find(audit.comment["software_agent_id"])
            audit_summary[:deleted_by].merge!(
              {
                "agent": {
                  "id": creation_agent.id,
                  "name": creation_agent.name
                }
              }
            )
          end
        end
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
end
