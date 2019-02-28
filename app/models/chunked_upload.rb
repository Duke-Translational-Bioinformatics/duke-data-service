class ChunkedUpload < Upload
  has_many :chunks, foreign_key: 'upload_id'

  after_create :initialize_storage

  validates :size, numericality:  {
    less_than: :max_size_bytes,
    message: ->(object, data) do
      "File size is currently not supported - maximum size is #{object.max_size_bytes}"
    end
  }, if: :storage_provider

  def manifest
    chunks.reorder(:number).collect do |chunk|
      {
        path: chunk.sub_path,
        etag: chunk.fingerprint_value,
        size_bytes: chunk.size
      }
    end
  end

  def purge_storage
    chunks.each do |chunk|
      chunk.purge_storage
      chunk.destroy
    end
    storage_provider.purge(self)
    self.update(purged_on: DateTime.now)
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

  def max_size_bytes
    storage_provider.max_chunked_upload_size
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

  def minimum_chunk_size
    storage_provider.suggested_minimum_chunk_size(self)
  end
end
