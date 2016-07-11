module RequestAudited
  def around_audit
    if Audited.store[:current_user]
      Audited.audit_class.as_user(Audited.store[:current_user]) do
        yield
      end
    else
      yield
    end
    if Audited.store[:audit_attributes]
      audits.last.update(Audited.store[:audit_attributes])
    end
  end
end
