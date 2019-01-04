class Upload < ActiveRecord::Base
  include JobTransactionable
  default_scope { order('created_at DESC') }
  audited
  belongs_to :project
  belongs_to :storage_provider
  has_many :chunks
  has_many :project_permissions, through: :project
  belongs_to :creator, class_name: 'User'
  has_many :fingerprints

  before_create :set_storage_container
  after_create :initialize_storage

  accepts_nested_attributes_for :fingerprints

  validates :project_id, presence: true
  validates :storage_container, immutable: true
  validates :name, presence: true
  validates :storage_provider_id, presence: true
  validates :size, presence: true
  validates :size, numericality:  {
    less_than: :max_size_bytes,
    message: ->(object, data) do
      "File size is currently not supported - maximum size is #{object.max_size_bytes}"
    end
  }, if: :storage_provider
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
    [storage_container, id].join('/')
  end

  def http_verb
    'GET'
  end

  def temporary_url(filename=nil)
    raise IntegrityException.new(error_message) if has_integrity_exception?
    raise ConsistencyException.new unless is_consistent?
    storage_provider.download_url(self, filename)
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

  def initialize_storage
    UploadStorageProviderInitializationJob.perform_later(
      job_transaction: UploadStorageProviderInitializationJob.initialize_job(self),
      storage_provider: storage_provider,
      upload: self
    )
  end

  def ready_for_chunks?
    storage_provider.chunk_upload_ready?(self)
  end

  def check_readiness!
    raise(ConsistencyException, 'Upload is not ready') unless ready_for_chunks?
    true
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

  def complete_and_validate_integrity
      begin
      storage_provider.complete_chunked_upload(self)
      update!({
        is_consistent: true
      })
    rescue IntegrityException => e
      integrity_exception(e.message)
    end
  end

  def set_storage_container
    self.storage_container = project_id
    storage_container
  end

  def purge_storage
    chunks.each do |chunk|
      chunk.purge_storage
      chunk.destroy
    end
    storage_provider.purge(self)
    self.update(purged_on: DateTime.now)
  end

  def max_size_bytes
    storage_provider.max_chunked_upload_size
  end

  def minimum_chunk_size
    storage_provider.suggested_minimum_chunk_size(self)
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
