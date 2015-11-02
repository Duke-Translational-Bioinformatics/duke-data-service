class Container < ActiveRecord::Base
  include SerializedAudit
  include Kinded

  audited
  belongs_to :project
	belongs_to :parent, class_name: "Folder"
  has_many :project_permissions, through: :project

  validates :name, presence: true

  def virtual_path
    if parent
      [parent.virtual_path, self.name].join('/')
    else
      "/#{self.name}"
    end
  end
end
