class FileVersionUrlSerializer < ActiveModel::Serializer
  attributes :http_verb, :host, :url, :http_headers

  def http_headers
    []
  end
end
