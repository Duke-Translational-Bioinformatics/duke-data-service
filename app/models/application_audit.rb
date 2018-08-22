class ApplicationAudit < Audited::Audit
  before_create do
    self.comment ||= {}
    self.comment[:software_agent_id] = user.current_software_agent&.id if user&.current_software_agent
  end
  def self.store_current_user(current_user)
    ::Audited.store[:audited_user] = current_user
  end

  def self.reset_store
    ::Audited.store.delete(:audited_user)
  end
end
