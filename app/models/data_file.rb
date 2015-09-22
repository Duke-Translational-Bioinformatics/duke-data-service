class DataFile < ActiveRecord::Base
  belongs_to :project
	belongs_to :folder
  belongs_to :upload
  has_many :project_permissions, through: :project

  validates :name, presence: true
  validates :project_id, presence: true
  validates :upload_id, presence: true

  def virtual_path
    if folder
      [folder.virtual_path, self.name].join('/')
    else
      "/#{self.name}"
    end
  end
end
