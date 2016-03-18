class StorageProvider < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  validates :display_name, presence: true, uniqueness: true
  validates :description, presence: true
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

  def auth_header
    {'X-Auth-Token' => auth_token}
  end

  def register_keys
    resp = HTTParty.post(
      storage_url,
      headers: auth_header.merge({
        'X-Account-Meta-Temp-URL-Key' => primary_key,
        'X-Account-Meta-Temp-URL-Key-2' => secondary_key
      })
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

  def build_signed_url(http_verb, sub_path, expiry, filename=nil)
    path = [root_path, sub_path].join('/')
    hmac_body = [http_verb, expiry, path].join("\n")
    signature = build_signature(hmac_body)
    signed_url = URI.encode("#{path}?temp_url_sig=#{signature}&temp_url_expires=#{expiry}")
    signed_url = signed_url + "&filename=#{URI.encode(filename)}" if filename
    signed_url
  end

  def get_account_info
    resp = HTTParty.get(
      "#{storage_url}",
      headers: auth_header
    )
    ([200,204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
    resp.headers
  end

  def get_containers
    resp = HTTParty.get(
      "#{storage_url}",
      headers: auth_header
    )
    ([200,204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
    resp.body.split("\n")
  end

  def get_container_meta(container)
    resp = HTTParty.head(
      "#{storage_url}/#{container}",
      headers: auth_header
    )
    return if resp.response.code.to_i == 404
    ([200,204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
     resp.headers
  end

  def get_container_objects(container)
    resp = HTTParty.get(
      "#{storage_url}/#{container}",
      headers: auth_header
    )
    return if resp.response.code.to_i == 404
    ([200,204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
     resp.body.split("\n")
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

  def delete_container(container)
    resp = HTTParty.delete(
      "#{storage_url}/#{container}",
      headers: auth_header
    )
    ([204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
  end

  def put_object(container, object, body)
    resp = HTTParty.put(
      "#{storage_url}/#{container}/#{object}",
      body: body,
      headers: auth_header
    )
    ([201].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
  end

  def put_object_manifest(container, object, manifest, content_type=nil, filename=nil)
    content_headers = {}
    if content_type && !content_type.empty?
      content_headers['content-type'] = content_type
    end
    if filename
      content_headers['content-disposition'] = "attachment; filename=#{filename}"
    end
    resp = HTTParty.put(
      "#{storage_url}/#{container}/#{object}?multipart-manifest=put",
      body: manifest.to_json,
      headers: auth_header.merge(content_headers)
    )
    ([201,202].include?(resp.response.code.to_i)) ||
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

  def get_object_metadata(container, object)
    resp = HTTParty.head(
      "#{storage_url}/#{container}/#{object}",
      headers: auth_header
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
    @auth_uri_resp.headers
  end
end
