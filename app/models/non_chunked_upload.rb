class NonChunkedUpload < Upload
  validates :size, numericality:  {
    less_than: :max_size_bytes,
    message: ->(object, data) do
      "File size is currently not supported - maximum size is #{object.max_size_bytes}"
    end
  }

  def max_size_bytes
    storage_provider&.max_upload_size
  end

  def single_file_upload_url
    storage_provider.single_file_upload_url(self)
  end

  def signed_url
    {
      http_verb: "PUT",
      host: storage_provider.url_root,
      url: single_file_upload_url,
      http_headers: []
    }
  end

  def purge_storage
    storage_provider.purge(self)
    self.update(purged_on: DateTime.now)
  end

  def complete_and_validate_integrity
    begin
      storage_provider.verify_upload_integrity(self)
      update!({ is_consistent: true })
    rescue IntegrityException => e
      integrity_exception(e.message)
    end
  end
end
