class Container < ApplicationRecord
  default_scope { order('created_at DESC') }
  include Kinded
  include Restorable
  include Purgable

  audited
  belongs_to :project
	belongs_to :parent, class_name: "Folder"
  belongs_to :deleted_from_parent, class_name: "Folder"
  has_many :project_permissions, through: :project
  has_many :tags, as: :taggable

  define_model_callbacks :set_parent_attribute

  validates :name, presence: true, unless: :is_deleted

  def ancestors
    if parent
      [parent.ancestors, parent].flatten
    else
      [project]
    end
  end

  def parent=(val)
    run_callbacks(:set_parent_attribute) do
      super(val)
    end
  end

  def parent_id=(val)
    run_callbacks(:set_parent_attribute) do
      super(val)
    end
  end

  def set_project_to_parent_project
    self.project = self.parent.project if self.parent
  end

  def move_to_trashbin
    self.is_deleted = true
    self.deleted_from_parent_id = self.parent_id
    self.parent_id = nil
  end

  def restore_from_trashbin(new_parent=nil)
    self.is_deleted = false
    if new_parent.nil?
      self.parent_id = self.deleted_from_parent_id
      self.deleted_from_parent_id = nil
    elsif new_parent.is_a? Folder
      self.deleted_from_parent_id = nil
      self.parent_id = new_parent.id
    elsif new_parent.is_a? Project
      self.parent_id = nil
      self.deleted_from_parent_id = nil
      self.project_id = new_parent.id
    else
      raise IncompatibleParentException.new("Objects can only be restored to a dds-folder or dds-project.::Perhaps you mistyped the object_kind.")
    end
  end
end
