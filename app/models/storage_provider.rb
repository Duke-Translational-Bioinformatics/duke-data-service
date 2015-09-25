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
    call_auth_uri['x-auth-token']
  end

  def storage_url
    call_auth_uri['x-storage-url']
  end

  def register_keys
    resp = HTTParty.post(
      storage_url,
      headers:{
        'X-Auth-Token' => auth_token,
        'X-Account-Meta-Temp-URL-Key' => primary_key,
        'X-Account-Meta-Temp-URL-Key-2' => secondary_key
      }
    )
    (resp.response.code.to_i == 204) || raise(StorageProviderException, resp.body)
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

  def get_account_info
    resp = HTTParty.get(
      "#{storage_url}",
      headers:{"X-Auth-Token" => auth_token}
    )
    ([200,204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
    resp
  end

  def put_container(container)
    resp = HTTParty.put(
      "#{storage_url}/#{container}",
      headers:{"X-Auth-Token" => auth_token}
    )
    ([201,202,204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
  end

  def delete_container(container)
    resp = HTTParty.delete(
      "#{storage_url}/#{container}",
      headers:{"X-Auth-Token" => auth_token}
    )
    ([204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
  end

  def put_object(container, object, body)
    resp = HTTParty.put(
      "#{storage_url}/#{container}/#{object}",
      body: body,
      headers:{"X-Auth-Token" => auth_token}
    )
    ([201].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
  end

  def put_object_manifest(container, object, manifest)
    resp = HTTParty.put(
      "#{storage_url}/#{container}/#{object}?multipart-manifest=put",
      body: manifest.to_json,
      headers:{"X-Auth-Token" => auth_token}
    )
    ([201,202].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
  end

  def delete_object(container, object)
    resp = HTTParty.delete(
      "#{storage_url}/#{container}/#{object}?multipart-manifest=delete",
      headers:{"X-Auth-Token" => auth_token}
    )
    ([200,204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
  end

  def get_object_metadata(container, object)
    resp = HTTParty.head(
      "#{storage_url}/#{container}/#{object}",
      headers:{"X-Auth-Token" => auth_token}
    )
    ([200,204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
     resp.headers
  end

  private
  def call_auth_uri
    begin
      @auth_uri_resp ||= HTTParty.get(
          "#{url_root}#{auth_uri}",
          headers: {
            'X-Auth-User' => service_user,
            'X-Auth-Key' => service_pass
          }
      )
    rescue Exception => e
      raise StorageProviderException, "Unexpected StorageProvider Error #{e.message}"
    end
    unless @auth_uri_resp.response.code.to_i == 200
      raise StorageProviderException, "Auth Failure: #{ @auth_uri_resp.body }"
    end
    @auth_uri_resp
  end
end
