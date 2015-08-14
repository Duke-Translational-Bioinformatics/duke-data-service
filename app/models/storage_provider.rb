class StorageProvider < ActiveRecord::Base
  validates :name, presence: true
  validates :url_root, presence: true
  validates :provider_version, presence: true
  validates :auth_uri, presence: true
  validates :service_user, presence: true
  validates :service_pass, presence: true
  validates :primary_key, presence: true
  validates :secondary_key, presence: true

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

  def get_signed_url(object)
    method = object.is_a?(Chunk) ? 'PUT' : 'GET'
    duration_in_seconds = 60*5 # 5 minutes
    expires = Time.now + duration_in_seconds

    subpath = (method == 'GET') ?
      [object.project.id, object.id].join('/') :
      [object.upload.project.id, object.upload.id, object.id, object.number].join('/')
    path = [
      "/#{provider_version}",
      name,
      subpath
    ].join('/')
    key = [primary_key, secondary_key].sample
    hmac_body = [method,expires.to_i,path].join("\n")
    digest = OpenSSL::Digest.new('sha1')
    signature = OpenSSL::HMAC.hexdigest(digest, key, hmac_body)
    return "#{path}?temp_url_sig=#{signature}&temp_url_expires=#{expires.to_i}"
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
