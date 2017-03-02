class ChildDeletionJob < ApplicationJob
  queue_as :child_deletion

  def perform(parent)
    parent.children.each do |child|
      child.update(is_deleted: true)
    end
  end
end
