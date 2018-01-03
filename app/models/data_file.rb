# Folder and DataFile are siblings in the Container class through single table inheritance.

class DataFile < Container
  include SearchableModel

  has_many :tags, as: :taggable
  has_many :meta_templates, as: :templatable

  after_set_parent_attribute :set_project_to_parent_project
  before_save :set_current_file_version_attributes
  before_save :set_file_versions_is_deleted, if: :is_deleted?

  validates :project_id, presence: true, immutable: true, unless: :is_deleted
  validates :upload, presence: true, unless: :is_deleted

  validates_each :upload, unless: :is_deleted do |record, attr, value|
    if record.upload
      if record.upload.error_at
        record.errors.add(attr, 'cannot have an error')
      elsif !record.upload.completed_at
        record.errors.add(attr, 'must be completed successfully')
      end
    end
  end

  delegate :http_verb, to: :upload

  def upload=(val)
    if file_versions.empty? || (current_file_version.persisted? && upload != val)
      build_file_version
    end
    current_file_version.upload = val
  end

  def upload
    current_file_version&.upload
  end

  def host
    upload.url_root
  end

  def url
    upload.temporary_url(name)
  end

  def set_file_versions_is_deleted
    file_versions.each do |fv|
      fv.is_deleted = true
    end
  end

  def kind
    super('file')
  end

  def current_file_version
    file_versions[-1]
  end

  def build_file_version
    file_versions.build(data_file: self)
  end

  def set_current_file_version_attributes
    current_file_version.attributes = {
      label: label
    }
    current_file_version
  end

  def as_indexed_json(options={})
    Search::DataFileSerializer.new(self).as_json
  end

  settings do
    mappings dynamic: 'false' do
      indexes :kind, type: "string", fields: {
        raw: {type: "string", index: "not_analyzed"}
      }

      indexes :name
      indexes :is_deleted, type: "boolean"

      indexes :tags do
        indexes :label, type: "string", fields: {
          raw: {type: "string", index: "not_analyzed"}
        }
      end

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
    return unless current_file_version
    create_audit = current_file_version.audits.find_by(action: "create")
    return unless create_audit
    create_audit.user
  end
end
