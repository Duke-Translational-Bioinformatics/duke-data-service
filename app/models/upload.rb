class Upload < ActiveRecord::Base
  include RequestAudited
  include JobTransactionable
  default_scope { order('created_at DESC') }
  audited
  belongs_to :project
  belongs_to :storage_provider
  has_many :chunks
  has_many :project_permissions, through: :project
  belongs_to :creator, class_name: 'User'
  has_many :fingerprints

  accepts_nested_attributes_for :fingerprints

  validates :project_id, presence: true
  validates :name, presence: true
  validates :size, presence: true
  validates :storage_provider_id, presence: true
  validates :creator_id, presence: true
  validates :completed_at, immutable: true, if: :completed_at_was
  validates :completed_at, immutable: true, if: :error_at_was
  validates :fingerprints, presence: true, if: :completed_at
  validates :fingerprints, absence: true, unless: :completed_at

  delegate :url_root, to: :storage_provider

  def object_path
    id
  end

  def sub_path
    [project_id, id].join('/')
  end

  def http_verb
    'GET'
  end

  def temporary_url(filename=nil)
    raise IntegrityException.new(error_message) if has_integrity_exception?
    raise ConsistencyException.new unless is_consistent?
    expiry = Time.now.to_i + storage_provider.signed_url_duration
    filename ||= name
    storage_provider.build_signed_url(http_verb, sub_path, expiry, filename)
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
    transaction do
      self.completed_at = DateTime.now
      if save
        UploadCompletionJob.perform_later(
          UploadCompletionJob.initialize_job(self),
          self.id
        )
        self
      end
    end
  end

  def has_integrity_exception?
    # this is currently the only use of the error attributes
    !error_at.nil?
  end

  def create_and_validate_storage_manifest
    begin
      response = storage_provider.put_object_manifest(project_id, id, manifest, content_type, name)
      meta = storage_provider.get_object_metadata(project_id, id)
      unless meta["content-length"].to_i == size
        raise IntegrityException, "reported size does not match size computed by StorageProvider"
      end
      update!({
        is_consistent: true
      })
    rescue StorageProviderException => e
      if e.message.match(/.*Etag.*Mismatch.*/)
        integrity_exception("reported chunk hash does not match that computed by StorageProvider")
      else
        raise e
      end
    rescue IntegrityException => e
      integrity_exception(e.message)
    end
  end

  private
  def integrity_exception(message)
    exactly_now = DateTime.now
    fingerprints.reload
    update!({
      error_at: exactly_now,
      error_message: message,
      is_consistent: true
    })
  end
end
