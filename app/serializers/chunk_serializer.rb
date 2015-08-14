class ChunkSerializer < ActiveModel::Serializer
  self.root = false
  attributes :http_verb, :host, :url, :http_headers
end
