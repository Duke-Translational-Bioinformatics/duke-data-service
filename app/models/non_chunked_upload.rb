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

  def purge_storage
    storage_provider.purge(self)
    self.update(purged_on: DateTime.now)
  end

  def complete_and_validate_integrity
  end
end
