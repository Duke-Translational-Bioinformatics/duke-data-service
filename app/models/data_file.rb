# Folder and DataFile are siblings in the Container class through single table inheritance.

class DataFile < Container
  belongs_to :upload
  has_many :file_versions, -> { order('version_number ASC') }, autosave: true
  has_many :tags, as: :taggable

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
end
