class NonChunkedUpload < Upload
  validates :size, numericality:  {
    less_than: :max_size_bytes,
    message: ->(object, data) do
      "File size is currently not supported - maximum size is #{object.max_size_bytes}"
    end
  }

  def max_size_bytes
    1
  end

  def purge_storage
  end

  def complete_and_validate_integrity
  end
end
