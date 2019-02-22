class ChunkedUpload < Upload
  has_many :chunks, foreign_key: 'upload_id'

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
end
