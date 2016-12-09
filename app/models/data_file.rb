# Folder and DataFile are siblings in the Container class through single table inheritance.

class DataFile < Container
  belongs_to :upload
  has_many :file_versions, -> { order('version_number ASC') }, autosave: true
  has_many :tags, as: :taggable
  has_many :meta_templates, as: :templatable

  after_set_parent_attribute :set_project_to_parent_project
  before_save :build_file_version, if: :new_file_version_needed?
  before_save :set_current_file_version_attributes
  before_save :set_file_versions_is_deleted, if: :is_deleted?

  validates :project_id, presence: true, immutable: true, unless: :is_deleted
  validates :upload_id, presence: true, unless: :is_deleted

  validates_each :upload, :upload_id, unless: :is_deleted do |record, attr, value|
    if record.upload
      if record.upload.error_at
        record.errors.add(attr, 'cannot have an error')
      elsif !record.upload.completed_at
        record.errors.add(attr, 'must be completed successfully')
      end
    end
  end

  delegate :http_verb, to: :upload

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
    file_versions.build
  end

  def set_current_file_version_attributes
    current_file_version.attributes = {
      upload: upload,
      label: label
    }
    current_file_version
  end

  def new_file_version_needed?
    file_versions.empty? ||
      current_file_version.upload != upload &&
      current_file_version.persisted?
  end

  def as_indexed_json(options={})
    Search::DataFileSerializer.new(self).as_json
  end

  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :id
      indexes :name
      indexes :is_deleted, type: "boolean"
      indexes :created_at, type: "date", format: "strict_date_optional_time||epoch_millis"
      indexes :updated_at, type: "date", format: "strict_date_optional_time||epoch_millis"
      indexes :label
      indexes :tags do
        indexes :label, type: "string", fields: {
          raw: {type: "string", index: "not_analyzed"}
        }
      end
      indexes :project do
        indexes :id, type: "string"
        indexes :name, type: "string"
      end

      indexes :parent do
        indexes :id, type: "string"
        indexes :name, type: "string"
      end

      indexes :creator do
        indexes :id, type: "string"
        indexes :username, type: "string"
        indexes :first_name, type: "string"
        indexes :last_name, type: "string"
        indexes :email, type: "string"
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
