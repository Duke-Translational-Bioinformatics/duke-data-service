# Folder and DataFile are siblings in the Container class through single table inheritance.

class DataFile < Container
  belongs_to :upload
  belongs_to :creator, class_name: 'User'
  has_many :file_versions
  has_many :tags, as: :taggable

  after_set_parent_attribute :set_project_to_parent_project
  before_update :build_file_version, if: :upload_id_changed?

  validates :project_id, presence: true, immutable: true, unless: :is_deleted
  validates :upload_id, presence: true, unless: :is_deleted
  validates :creator_id, presence: true, unless: :is_deleted

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
    file_versions.build(
      upload_id: upload_id_was,
      label: label_was
    )
  end
end
