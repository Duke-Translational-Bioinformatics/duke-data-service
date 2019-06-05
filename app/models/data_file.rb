# Folder and DataFile are siblings in the Container class through single table inheritance.

class DataFile < Container
  include Restorable
  include Purgable
  include ChildMinder
  include SearchableModel

  # change this variable to a new uuid (lowercase letters!)
  # any time the mappings below change
  def self.mapping_version
    '6518bcef-69d7-457d-9ee4-a74cb64b698d'
  end

  # change this to a new uuid (lowercase letters!) any time
  #  - a migration is created to add/remove fields
  #    and its serializers (standard and search)
  #  - relationships are added to/removed from the serializers
  def self.migration_version
    '366f0fd9-5526-4479-b4f1-5c61e8c1eb53'
  end

  has_many :file_versions, -> { order('version_number ASC') }, autosave: true
  has_many :tags, as: :taggable
  has_many :meta_templates, as: :templatable
  alias children file_versions

  after_set_parent_attribute :set_project_to_parent_project
  before_save :set_current_file_version_attributes
  before_save :set_etag, if: :anything_changed?

  def anything_changed?
    changed? || file_versions.any?(&:changed?)
  end

  def set_etag
    self.etag = SecureRandom.hex
  end

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

      indexes :name, type: "string"
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

  def restore(child)
    raise TrashbinParentException.new("#{kind} #{id} is deleted, and cannot restore its versions.::Restore #{kind} #{id}.") if is_deleted?
    raise IncompatibleParentException.new("Parent dds-file can only restore its own dds-file-version objects.::Perhaps you mistyped the object_kind or parent_kind.") unless child.is_a? FileVersion
    raise IncompatibleParentException.new("dds-file-version objects can only be restored to their original dds-file.::Try not supplying a parent in the payload.") unless child.data_file_id == id
    child.is_deleted = false
  end
end
