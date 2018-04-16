module UnRestorable
  extend ActiveSupport::Concern
  attr_accessor :force_purgation

  included do
    before_update :manage_deletion
  end

  def manage_deletion
    if (will_save_change_to_is_deleted? && is_deleted?) || force_purgation
      @child_job = ChildPurgationJob
    end
  end

  # ChildMinder method
  def purge_children(page)
    paginated_children(page).each do |child|
      child.current_transaction = current_transaction if child.class.include? JobTransactionable
      child.update(is_deleted: true, is_purged: true)
    end
  end
end
