class Container < ActiveRecord::Base
  include SerializedAudit
  include Kinded

  audited
  belongs_to :project
	belongs_to :parent, class_name: "Folder"
  has_many :project_permissions, through: :project

  validates :name, presence: true

  def ancestors
    if parent
      [parent.ancestors, parent].flatten
    else
      [project]
    end
  end

  def virtual_path
    ancestors.collect do |a|
      {
        kind: a.kind,
        id: a.id,
        name: a.name
      }
    end
  end
end
