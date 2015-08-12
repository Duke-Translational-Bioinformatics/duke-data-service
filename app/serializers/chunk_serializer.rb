class ChunkSerializer < ActiveModel::Serializer
  self.root = false
  attributes :http_verb, :host, :url, :http_headers

  def http_verb
    'PUT'
  end
  def host
    ''
  end
  def url
    ''
  end
  def http_headers
    ''
  end
end
