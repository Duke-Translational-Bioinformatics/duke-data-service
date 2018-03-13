module ChildMinder
  extend ActiveSupport::Concern

  included do
    after_update :manage_children
  end

  def manage_children
    if has_children? && @child_job
      newly_deleted = will_save_change_to_is_deleted? && is_deleted?
      (1..paginated_children.total_pages).each do |page|
        @child_job.perform_later(
          @child_job.initialize_job(self),
          self,
          page
        )
      end
    end
  end

  def has_children?
    children.count > 0
  end

  private

  def paginated_children(page=1)
    children.page(page).per(Rails.application.config.max_children_per_job)
  end
end
