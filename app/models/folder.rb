# Folder and DataFile are siblings in the Container class through single table inheritance.

class Folder < Container
  has_many :children, class_name: "Container", foreign_key: "parent_id", autosave: true
  has_many :folders, -> { readonly }, foreign_key: "parent_id"

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

  def is_deleted=(val)
    if val
      children.each do |child|
        child.is_deleted = true
      end
    end
    super(val)
  end

  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :id
      indexes :name
      indexes :is_deleted, type: "boolean"
      indexes :created_at, type: "date", format: "strict_date_optional_time||epoch_millis"
      indexes :updated_at, type: "date", format: "strict_date_optional_time||epoch_millis"
      indexes :tags do
        indexes :label, type: "string", fields: {
          raw: {type: "string", index: "not_analyzed"}
        }
      end
    end
  end
end
