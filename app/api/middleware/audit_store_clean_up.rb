class AuditStoreCleanUp < Grape::Middleware::Base
  def after
    Audited.store.clear
    return
  end
end
