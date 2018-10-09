class StorageProvider < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  validates :display_name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :name, presence: true

  ### TODO refactor these methods to be more abstract
  def signed_url_duration
    60*5 # 5 minutes
  end

  def root_path
    root_path = ['',
      provider_version,
      name
    ].join('/')
  end

  def digest
    @digest ||= OpenSSL::Digest.new('sha1')
  end

  def build_signature(hmac_body, key = primary_key)
    OpenSSL::HMAC.hexdigest(digest, key, hmac_body)
  end

  def build_signed_url(http_verb, sub_path, expiry, filename=nil)
    path = [root_path, sub_path].join('/')
    hmac_body = [http_verb, expiry, path].join("\n")
    signature = build_signature(hmac_body)
    signed_url = URI.encode("#{path}?temp_url_sig=#{signature}&temp_url_expires=#{expiry}")
    signed_url = signed_url + "&filename=#{URI.encode(filename)}" if filename
    signed_url
  end

  def put_container(container)
    resp = HTTParty.put(
      "#{storage_url}/#{container}",
      headers: auth_header.merge({
        "X-Container-Meta-Access-Control-Allow-Origin" => "*"
      })
    )
    ([201,202,204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
  end

  def delete_object_manifest(container, object)
    resp = HTTParty.delete(
      "#{storage_url}/#{container}/#{object}?multipart-manifest=delete",
      headers: auth_header
    )
    ([200,204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
  end

  def delete_object(container, object)
    resp = HTTParty.delete(
      "#{storage_url}/#{container}/#{object}",
      headers: auth_header
    )
    ([200,204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
  end
end
