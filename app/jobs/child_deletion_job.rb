class ChildDeletionJob < ApplicationJob
  queue_as self.name.underscore.gsub('_job','').to_sym

  def perform(parent)
    parent.children.each do |child|
      child.update(is_deleted: true)
    end
  end
end
