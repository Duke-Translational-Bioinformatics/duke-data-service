module RequestAudited
  def around_audit
    current_user = Audited.store[:current_user]
    audit_attributes = Audited.store[:audit_attributes]
    if current_user
      if current_user.current_software_agent
        audit_attributes[:comment][:software_agent_id] = current_user.current_software_agent.id 
      end
      Audited.audit_class.as_user(current_user) do
        yield
      end
    else
      yield
    end
    if audit_attributes
      audit = audits.last
      audit_attributes[:comment] = (audit.comment || {}).merge(audit_attributes[:comment])
      audits.last.update(audit_attributes)
    end
  end
end
