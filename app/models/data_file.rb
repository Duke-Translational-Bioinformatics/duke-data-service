# Folder and DataFile are siblings in the Container class through single table inheritance.

class DataFile < Container
  belongs_to :upload
  has_many :file_versions

  after_set_parent_attribute :set_project_to_parent_project
  before_create :build_file_version
  before_update :build_file_version, if: :upload_id_changed?

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

  def build_file_version
    if file_versions.empty? || file_versions.last.persisted?
      file_versions.build(
        upload_id: upload_id_was || upload_id,
        label: label_was || label
      )
    end
    file_versions.last
  end
end
