# Folder and DataFile are siblings in the Container class through single table inheritance.

class Folder < Container
  has_many :children, class_name: "Container", foreign_key: "parent_id", autosave: true

  after_set_parent_attribute :set_project_to_parent_project

  validates :project_id, presence: true, immutable: true
  validates_each :parent, :parent_id do |record, attr, value|
    record.errors.add(attr, 'cannot be itself') if record.parent == record
    record.errors.add(attr, 'cannot be a child folder') if record.parent &&
      record.parent.respond_to?(:ancestors) &&
      record.parent.reload.ancestors.include?(record)
  end

  def descendants
    descendants = project.containers.select { |c| c.ancestors.include?(self) }
    descendants_ids = descendants.collect { |d| d.id }
    project.containers.where(id: descendants_ids)
  end

  def is_deleted=(val)
    if val
      children.each do |child|
        child.is_deleted = true
      end
    end
    super(val)
  end
end
