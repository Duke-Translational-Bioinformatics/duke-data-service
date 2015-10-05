class Folder < ActiveRecord::Base
  include SerializedAudit
  audited
  has_many :children, class_name: "Folder", foreign_key: "parent_id"
  belongs_to :project
	belongs_to :parent, class_name: "Folder"
  has_many :project_permissions, through: :project

  validates :name, presence: true
  validates :project_id, presence: true

  def virtual_path
    if parent
      [parent.virtual_path, self.name].join('/')
    else
      "/#{self.name}"
    end
  end
end
