# Folder and DataFile are siblings in the Container class through single table inheritance.

class DataFile < Container
  belongs_to :upload
  belongs_to :creator, class_name: 'User'

  after_set_parent_attribute :set_project_to_parent_project

  validates :project_id, presence: true, immutable: true
  validates :upload_id, presence: true
  validates :creator_id, presence: true

  validates_each :upload, :upload_id do |record, attr, value|
    if record.upload
      if record.upload.creator_id != record.creator_id
        record.errors.add(attr, 'created by another user')
      elsif record.upload.error_at
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
end
