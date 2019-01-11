class ProjectStorageProvider < ApplicationRecord
  belongs_to :project
  belongs_to :storage_provider
end
