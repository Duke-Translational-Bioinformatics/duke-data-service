class Upload < ActiveRecord::Base
  belongs_to :project
  belongs_to :storage_provider
  has_many :chunks
  has_many :project_permissions, through: :project

  validates :project_id, presence: true
  validates :name, presence: true
  validates :size, presence: true
  validates :fingerprint_value, presence: true
  validates :fingerprint_algorithm, presence: true
  validates :storage_provider_id, presence: true

  def sub_path
    [project_id, id].join('/')
  end

  def temporary_url
    http_verb = 'GET'
    expiry = updated_at.to_i + storage_provider.signed_url_duration
    storage_provider.build_signed_url(http_verb, sub_path, expiry)
  end

  def manifest
    chunks.collect do |chunk|
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
