class StorageProvider < ActiveRecord::Base
  validates :name, presence: true
  validates :url_root, presence: true
  validates :provider_version, presence: true
  validates :auth_uri, presence: true
  validates :service_user, presence: true
  validates :service_pass, presence: true
  validates :primary_key, presence: true
  validates :secondary_key, presence: true

  def auth_token
  end

  def storage_url
  end

  def register_keys
    authenticate
    resp = HTTParty.post(
            @storage_url,
              headers:{
                "X-Auth-Token" => @auth_token,
                'X-Account-Meta-Temp-URL-Key' => primary_key,
                'X-Account-Meta-Temp-URL-Key-2' => secondary_key
              }
    )
    unless resp.response.code.to_i == 204
      raise StorageProviderException, resp.body
    end
  end

  def root_path
    root_path = ['',
      provider_version,
      name
    ].join('/')
  end

  def signed_url_duration
    60*5 # 5 minutes
  end

  def digest
    @digest ||= OpenSSL::Digest.new('sha1')
  end

  def build_signature(hmac_body, key = primary_key)
    OpenSSL::HMAC.hexdigest(digest, key, hmac_body)
  end

  def build_signed_url(http_verb, sub_path, expiry)
    path = [root_path, sub_path].join('/')
    hmac_body = [http_verb, expiry, path].join("\n")
    signature = build_signature(hmac_body)
    URI.encode("#{path}?temp_url_sig=#{signature}&temp_url_expires=#{expiry}")
  end

  def create_slo_manifest(upload)
    manifest_document = upload.chunks.map {|chunk|
      {
        "path" => [upload.project.id, upload.id, chunk.id, chunk.number].join('/'),
        "etag" => chunk.fingerprint_value,
        "size_bytes" => chunk.size
      }
    }
    authenticate
    path = [
      @storage_url,
      upload.project.id,
      upload.id
    ].join('/')
    resp = HTTParty.put(
      "#{path}?multipart-manifest=put",
      body: manifest_document.to_json,
      headers:{"X-Auth-Token" => @auth_token}
    )
    unless resp.response.code.to_i == 201
      raise StorageProviderException, resp.body
    end
  end

  private
  def authenticate
    return if @auth_token
    auth_resp = HTTParty.get(
        "#{url_root}#{auth_uri}",
        headers: {
          'X-Auth-User' => service_user,
          'X-Auth-Key' => service_pass
        }
    )
    unless auth_resp.response.code.to_i == 200
      raise StorageProviderException, "Auth Failure: #{ auth_resp.body }"
    end
    @storage_url = auth_resp['x-storage-url']
    @auth_token = auth_resp['x-auth-token']
  end
end

class StorageProviderException < StandardError
end
