class DataFileSummarySerializer < ActiveModel::Serializer
  attributes :id, :name, :size, :file_url, :hashes, :ancestors

  def ancestors
    object.ancestors.collect do |ancestor|
      {
        kind: ancestor.kind,
        id: ancestor.id,
        name: ancestor.name,
      }
    end
  end

  def hashes
    object.upload.fingerprints.collect do |hash|
      {
        value: hash.value,
        algorithm: hash.algorithm
      }
    end
  end

  def file_url
    {
      http_verb: object.http_verb,
      host: object.host,
      url: object.url,
      http_headers: []
    }
  end

  def size
    object.upload.size
  end
end
