class Chunk < ApplicationRecord
  default_scope { order('created_at DESC') }
  audited
  after_destroy :update_upload_etag

  belongs_to :upload
  has_one :storage_provider, through: :upload
  has_one :project, through: :upload
  has_many :project_permissions, through: :upload

  validates :upload, presence: true
  validates :number, presence: true,
    uniqueness: {scope: [:upload_id], case_sensitive: false}
  validates :number, numericality:  {
    greater_than_or_equal_to: :minimum_chunk_number
  }, if: :storage_provider
  validates :size, presence: true
  validates :size, numericality:  {
    less_than: :chunk_max_size_bytes
  }, if: :storage_provider

  validates :fingerprint_value, presence: true
  validates :fingerprint_algorithm, presence: true
  validate :upload_chunk_maximum, if: :storage_provider

  delegate :project_id, :minimum_chunk_size, :storage_container, to: :upload
  delegate :chunk_max_size_bytes, :minimum_chunk_number, to: :storage_provider

  def http_verb
    'PUT'
  end

  def host
    storage_provider.url_root
  end

  def http_headers
    []
  end

  def object_path
    [upload_id, number].join('/')
  end

  def sub_path
    [storage_container, object_path].join('/')
  end

  def url
    begin
      storage_provider.chunk_upload_url(self)
    rescue StorageProviderException => e
      if e.message == 'Upload is not ready'
        raise ConsistencyException, e.message if e.message == 'Upload is not ready'
      else
        raise e
      end
    end
  end

  def purge_storage
    storage_provider.purge(self)
  end

  private

  def upload_chunk_maximum
    if storage_provider.chunk_max_reached?(self)
      errors[:base] << 'maximum upload chunks exceeded.'
    end
  end

  def update_upload_etag
    last_audit = self.audits.last
    new_comment = last_audit.comment ? last_audit.comment.merge({raised_by_audit: last_audit.id}) : {raised_by_audit: last_audit.id}
    self.upload.update(etag: SecureRandom.hex, audit_comment: new_comment)
    last_parent_audit = self.upload.audits.last
    last_parent_audit.update(request_uuid: last_audit.request_uuid)
  end
end
