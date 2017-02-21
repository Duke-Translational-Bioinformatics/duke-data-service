class FolderDeletionJob < ApplicationJob
  queue_as self.name.underscore.gsub('_job','').to_sym

  def perform(folder_id)
    folder = Folder.find(folder_id)
    folder.update(is_deleted: true)
  end
end
