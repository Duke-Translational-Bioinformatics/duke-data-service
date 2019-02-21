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
end
