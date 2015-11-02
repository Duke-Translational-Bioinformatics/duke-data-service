# Folder and DataFile are siblings in the Container class through single table inheritance.

class Folder < Container
  has_many :children, class_name: "Folder", foreign_key: "parent_id"

  validates :project_id, presence: true, immutable: true
  validates :is_deleted, absence: true, if: :children_present?

  def children_present?
    !children.empty?
  end
end
