class StorageProvider < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  validates :display_name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :name, presence: true
end
