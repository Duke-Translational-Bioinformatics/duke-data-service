# Folder and DataFile are siblings in the Container class through single table inheritance.

class Folder < Container
  include ChildMinder

  include SearchableModel
  # change this to a new uuid any time
  #  - a migration is created to add/remove fields
  #    and its serializers (standard and search)
  #  - relationships are added to/removed from the serializers
  @@migration_version = 'DA463742-2D1D-4DAC-9AB3-24D81754134F'

  # change this variable to a new uuid any time the mappings below change
  @@mapping_version = '8A9172F5-3B5E-4E1A-9DE9-06C61D23A54D'

  def self.mapping_version
    @@mapping_version
  end

  def self.migration_version
    @@migration_version
  end

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
end
