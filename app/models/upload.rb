class Upload < ActiveRecord::Base
  belongs_to :project
  belongs_to :storage_provider
  has_many :chunks

  validates :name, presence: true
end
