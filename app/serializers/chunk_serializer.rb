class ChunkSerializer < ActiveModel::Serializer
  attributes :http_verb, :host, :url, :http_headers
end
