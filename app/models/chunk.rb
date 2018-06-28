class Chunk < ActiveRecord::Base
  include RequestAudited
  default_scope { order('created_at DESC') }
  audited
  after_destroy :update_upload_etag

  belongs_to :upload
  has_one :storage_provider, through: :upload
  has_one :project, through: :upload
  has_many :project_permissions, through: :upload

  validates :upload_id, presence: true
  validates :number, presence: true,
    uniqueness: {scope: [:upload_id], case_sensitive: false}
  validates :size, presence: true
  validates :size, numericality:  {
    less_than: :chunk_max_size_bytes
  }, if: :storage_provider

  validates :fingerprint_value, presence: true
  validates :fingerprint_algorithm, presence: true
  validate :upload_chunk_maximum, if: :storage_provider

  delegate :project_id, :minimum_chunk_size, :storage_container, to: :upload
  delegate :chunk_max_size_bytes, to: :storage_provider

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

  def expiry
    updated_at.to_i + storage_provider.signed_url_duration
  end

  def url
    storage_provider.build_signed_url(http_verb, sub_path, expiry)
  end

  def purge_storage
    begin
      storage_provider.delete_object(storage_container, object_path)
    rescue StorageProviderException => e
      unless e.message.match /Not Found/
        raise e
      end
    end
  end

  def total_chunks
    upload.chunks.count
  end

  private

  def upload_chunk_maximum
    unless total_chunks < storage_provider.chunk_max_number
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
