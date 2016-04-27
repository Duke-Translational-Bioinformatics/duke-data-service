# Folder and DataFile are siblings in the Container class through single table inheritance.

class DataFile < Container
  belongs_to :upload
  has_many :file_versions, -> { order('version_number DESC') }

  after_set_parent_attribute :set_project_to_parent_project
  before_save :build_file_version, if: :new_file_version_needed?
  before_save :set_current_file_version_attributes

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

  def kind
    super('file')
  end

  def current_file_version
    file_versions.last
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
