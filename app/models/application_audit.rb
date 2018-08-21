class ApplicationAudit < Audited::Audit
  before_create do
    self.comment ||= {}
    self.comment[:software_agent_id] = user&.current_software_agent&.id
  end
  def self.store_current_user(current_user)
    ::Audited.store[:audited_user] = current_user
  end
end
