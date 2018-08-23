module ProjectUpdater
  extend ActiveSupport::Concern

  included do
    after_save :update_project_etag, if: :saved_changes?
    after_destroy :update_project_etag
  end

  def update_project_etag
    last_audit = self.audits.last
    new_comment = last_audit.comment ? last_audit.comment.merge({raised_by_audit: last_audit.id}) : {raised_by_audit: last_audit.id}
    self.project.update(etag: SecureRandom.hex)
    last_parent_audit = self.project.audits.last
    last_parent_audit.update(request_uuid: last_audit.request_uuid, comment: new_comment)
  end
end
