class Folder < ActiveRecord::Base
  has_many :children, class_name: "Folder", foreign_key: "folder_id"
  belongs_to :project
	belongs_to :folder
  has_many :project_permissions, through: :project

  validates :name, presence: true
  validates :project_id, presence: true

  def virtual_path
    if folder
      [folder.virtual_path, self.name].join('/')
    else
      "/#{self.name}"
    end
  end
end
