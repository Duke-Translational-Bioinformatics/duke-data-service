module RequestAudited
  def around_audit
    audit_attributes = Audited.store[:audit_attributes]
    yield
    if audit_attributes
      audit = audits.last
      comment = (audit.comment || {}).merge(audit_attributes[:comment])
      audits.last.update(comment: comment)
    end
  end
end
