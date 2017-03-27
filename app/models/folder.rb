# Folder and DataFile are siblings in the Container class through single table inheritance.

class Folder < Container
  include ChildMinder

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

  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :kind, type: "string", index: "not_analyzed"
      indexes :id, type: "string", index: "not_analyzed"
      indexes :label

      indexes :parent do
        indexes :id, type: "string", index: "not_analyzed"
        indexes :name, type: "string"
      end

      indexes :name
      indexes :is_deleted, type: "boolean"
      indexes :audit do
        indexes :created_on, type: "date", format: "strict_date_optional_time||epoch_millis"
        indexes :created_by do
          indexes :id, type: "string", index: "not_analyzed"
          indexes :username
          indexes :full_name
          indexes :agent do
            indexes :id, type: "string", index: "not_analyzed"
            indexes :name
          end
        end

        indexes :last_updated_on, type: "date", format: "strict_date_optional_time||epoch_millis"
        indexes :last_updated_by do
          indexes :id, type: "string", index: "not_analyzed"
          indexes :username
          indexes :full_name
          indexes :agent do
            indexes :id, type: "string", index: "not_analyzed"
            indexes :name
          end
        end

        indexes :deleted_on, type: "date", format: "strict_date_optional_time||epoch_millis"
        indexes :deleted_by do
          indexes :id, type: "string", index: "not_analyzed"
          indexes :username
          indexes :full_name
          indexes :agent do
            indexes :id, type: "string", index: "not_analyzed"
            indexes :name
          end
        end
      end

      indexes :created_at, type: "date", format: "strict_date_optional_time||epoch_millis"
      indexes :updated_at, type: "date", format: "strict_date_optional_time||epoch_millis"

      indexes :project do
        indexes :id, type: "string", index: "not_analyzed"
        indexes :name, type: "string"
      end

      indexes :ancestors do
        indexes :kind, type: "string", index: "not_analyzed"
        indexes :id, type: "string", index: "not_analyzed"
        indexes :name
      end

      indexes :creator do
        indexes :id, type: "string", index: "not_analyzed"
        indexes :username, type: "string"
        indexes :first_name, type: "string"
        indexes :last_name, type: "string"
        indexes :email, type: "string"
      end

    end
  end

  def creator
    creation_audit = audits.find_by(action: "create")
    return unless creation_audit
    creation_audit.user
  end
end
