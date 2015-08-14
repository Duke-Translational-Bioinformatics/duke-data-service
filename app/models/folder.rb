class Folder < ActiveRecord::Base
  has_many :children, class_name: "Folder", foreign_key: "parent_id"
  belongs_to :project
	belongs_to :parent, class_name: "Folder"

  validates :name, presence: true
  validates :project_id, presence: true
end
