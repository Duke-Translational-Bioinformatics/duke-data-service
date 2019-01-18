class ApplicationAudit < Audited::Audit
  before_save { self.class.generate_current_request_uuid }
  before_create do
    self.comment ||= {}
    self.comment.merge!(self.class.current_comment) if self.class.current_comment
    self.comment[:software_agent_id] = user.current_software_agent&.id if user&.current_software_agent
  end

  def self.current_user=(current_user)
    ::Audited.store[:audited_user] = current_user
  end

  def self.current_user
    ::Audited.store[:audited_user]
  end

  def self.current_request_uuid=(request_uuid)
    ::Audited.store[:current_request_uuid] = request_uuid
  end

  def self.current_request_uuid
    ::Audited.store[:current_request_uuid]
  end

  def self.generate_current_request_uuid
    self.current_request_uuid ||= SecureRandom.uuid
  end

  def self.current_remote_address=(remote_address)
    ::Audited.store[:current_remote_address] = remote_address
  end

  def self.current_remote_address
    ::Audited.store[:current_remote_address]
  end

  def self.current_comment=(comment)
    ::Audited.store[:current_comment] = comment
  end

  def self.current_comment
    ::Audited.store[:current_comment]
  end

  def self.set_current_env_from_request_uuid(request_uuid)
    request_audit = ApplicationAudit.where(request_uuid: request_uuid).last
    ApplicationAudit.current_request_uuid = request_uuid
    ApplicationAudit.current_user = request_audit&.user
    ApplicationAudit.current_remote_address = request_audit&.remote_address
    ApplicationAudit.current_comment = request_audit&.comment
  end

  def self.clear_store
    [:audited_user, :current_request_uuid, :current_remote_address, :current_comment].each { |k| ::Audited.store.delete(k) }
  end
end
