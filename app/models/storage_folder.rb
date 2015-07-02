class StorageFolder < ActiveRecord::Base
  belongs_to :project

  validates :project_id, presence: true
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :storage_service_uuid, presence: true
end
