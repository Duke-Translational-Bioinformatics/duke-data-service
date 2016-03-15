class FileVersion < ActiveRecord::Base
  include Kinded

  audited
  belongs_to :data_file
  belongs_to :upload
  belongs_to :creator, class_name: 'User'

  validates :upload_id, presence: true, unless: :is_deleted
  validates :creator_id, presence: true, unless: :is_deleted

  validates_each :upload, :upload_id, unless: :is_deleted do |record, attr, value|
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

  delegate :name, to: :data_file
  delegate :http_verb, to: :upload

  def host
    upload.url_root
  end

  def url
    upload.temporary_url(name)
  end

  def kind
    super('file-version')
  end
end
