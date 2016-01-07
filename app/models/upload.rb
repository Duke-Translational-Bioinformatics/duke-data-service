class Upload < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  include SerializedAudit
  audited
  belongs_to :project
  belongs_to :storage_provider
  has_many :chunks
  has_many :project_permissions, through: :project
  belongs_to :creator, class_name: 'User'

  validates :project_id, presence: true
  validates :name, presence: true
  validates :size, presence: true
  validates :storage_provider_id, presence: true
  validates :creator_id, presence: true

  delegate :url_root, to: :storage_provider

  def sub_path
    [project_id, id].join('/')
  end

  def http_verb
    'GET'
  end

  def temporary_url
    expiry = Time.now.to_i + storage_provider.signed_url_duration
    storage_provider.build_signed_url(http_verb, sub_path, expiry)
  end

  def manifest
    chunks.reorder(:number).collect do |chunk|
      {
        path: chunk.sub_path,
        etag: chunk.fingerprint_value,
        size_bytes: chunk.size
      }
    end
  end

  def complete
    begin
      response = storage_provider.put_object_manifest(project_id, id, manifest)
      meta = storage_provider.get_object_metadata(project_id, id)
      unless meta["content-length"].to_i == size
        integrity_exception("reported size does not match size computed by StorageProvider")
      end
      update_attribute(:completed_at, DateTime.now)
    rescue StorageProviderException => e
      if e.message.match(/.*Etag.*Mismatch.*/)
        integrity_exception("reported chunk hash does not match that computed by StorageProvider")
      else
        raise e
      end
    end
  end

  private
  def integrity_exception(message)
    exactly_now = DateTime.now
    update_attributes({
      completed_at: exactly_now,
      error_at: exactly_now,
      error_message: message
    })
    raise IntegrityException, message
  end
end
