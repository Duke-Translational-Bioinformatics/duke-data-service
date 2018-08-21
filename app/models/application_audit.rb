class ApplicationAudit < Audited::Audit
  def self.store_current_user(current_user)
    ::Audited.store[:audited_user] = current_user
  end
end
