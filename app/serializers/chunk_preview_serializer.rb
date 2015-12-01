class ChunkPreviewSerializer < ActiveModel::Serializer
  attributes :number, :size, :hash

  def hash
    {
      value: object.fingerprint_value,
      algorithm: object.fingerprint_algorithm,
    }
  end
end
