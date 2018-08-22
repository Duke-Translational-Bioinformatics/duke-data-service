class ApplicationAudit < Audited::Audit
  before_create do
    self.comment ||= {}
    self.comment[:software_agent_id] = user.current_software_agent&.id if user&.current_software_agent
  end

  def self.store_current_user(current_user)
    ::Audited.store[:audited_user] = current_user
  end

  def self.store_current_request_uuid(request_uuid)
    ::Audited.store[:current_request_uuid] = request_uuid
  end

  def self.store_current_remote_address(remote_address)
    ::Audited.store[:current_remote_address] = remote_address
  end

  def self.clear_store
    [:audited_user, :current_request_uuid, :current_remote_address].each { |k| ::Audited.store.delete(k) }
  end
end
