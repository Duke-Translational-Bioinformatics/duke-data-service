# Folder and DataFile are siblings in the Container class through single table inheritance.

class Folder < Container
  include ChildMinder
  include SearchableModel

  has_many :children, class_name: "Container", foreign_key: "parent_id", autosave: true
  has_many :folders, -> { readonly }, foreign_key: "parent_id"
  has_many :meta_templates, as: :templatable

  after_set_parent_attribute :set_project_to_parent_project

  validates :project_id, presence: true, immutable: true
  validates_each :parent, :parent_id do |record, attr, value|
    record.errors.add(attr, 'cannot be itself') if record.parent == record
    record.errors.add(attr, 'cannot be a child folder') if record.parent &&
      record.parent.respond_to?(:ancestors) &&
      record.parent.reload.ancestors.include?(record)
  end

  def folder_ids
    (folders.collect {|x| [x.id, x.folder_ids]}).flatten
  end

  def descendants
    project.containers.where(parent_id: [id, folder_ids].flatten)
  end

  def as_indexed_json(options={})
    Search::FolderSerializer.new(self).as_json
  end

  settings do
    mappings dynamic: 'false' do
      indexes :kind, type: "string", fields: {
        raw: {type: "string", index: "not_analyzed"}
      }

      indexes :name
      indexes :is_deleted, type: "boolean"

      indexes :project do
        indexes :id, type: "string", fields: {
          raw: {type: "string", index: "not_analyzed"}
        }
        indexes :name, type: "string", fields: {
          raw: {type: "string", index: "not_analyzed"}
        }
      end
    end
  end

  def creator
    creation_audit = audits.find_by(action: "create")
    return unless creation_audit
    creation_audit.user
  end

  def restore(child)
    raise TrashbinParentException.new("#{kind} #{id} is deleted, and cannot restore children.::Restore #{kind} #{id}.") if is_deleted?
    raise IncompatibleParentException.new("Folders can only restore dds-file or dds-folder objects.::Perhaps you mistyped the object_kind.") unless child.is_a? Container
    child.parent_id = id
    child.project_id = project_id
    child.is_deleted = false
  end
end
