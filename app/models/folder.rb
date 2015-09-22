class Folder < ActiveRecord::Base
  after_initialize :init

  has_many :children, class_name: "Folder", foreign_key: "folder_id"
  belongs_to :project
	belongs_to :folder
  has_many :project_permissions, through: :project

  validates :name, presence: true
  validates :project_id, presence: true

  def init
    self.is_deleted = false if self.is_deleted.nil?
    self.save
  end

  def virtual_path
    if folder
      [folder.virtual_path, self.name].join('/')
    else
      "/#{self.name}"
    end
  end
end
