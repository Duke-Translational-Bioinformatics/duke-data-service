module RequestAudited
  def around_audit
    audit_attributes = Audited.store[:audit_attributes]
    yield
    if audit_attributes
      audit = audits.last
      audit_attributes[:comment] = (audit.comment || {}).merge(audit_attributes[:comment])
      audits.last.update(audit_attributes)
    end
  end
end
