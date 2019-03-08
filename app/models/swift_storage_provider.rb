class SwiftStorageProvider < StorageProvider
  validates :url_root, presence: true
  validates :provider_version, presence: true
  validates :auth_uri, presence: true
  validates :service_user, presence: true
  validates :service_pass, presence: true
  validates :primary_key, presence: true
  validates :secondary_key, presence: true
  validates :chunk_max_number, presence: true
  validates :chunk_max_size_bytes, presence: true

  # StorageProvider Implementation
  def configure
    register_keys
  end

  def is_ready?
    #storage_provider must be accessible over http without network or CORS issues
    sp_acct = get_account_info
    # storage_provider must be configured
    unless sp_acct.has_key?("x-account-meta-temp-url-key") &&
           sp_acct.has_key?("x-account-meta-temp-url-key-2") &&
           sp_acct["x-account-meta-temp-url-key"] == primary_key &&
           sp_acct["x-account-meta-temp-url-key-2"] == secondary_key
      raise StorageProviderException, 'storage_provider needs to be configured'
    end
    return true
  end

  def initialize_project(project)
    put_container(project.id)
  end

  def is_initialized?(project)
    return true if get_container_meta(project.id)
  end

  def single_file_upload_url(upload)
    build_signed_url(
      'POST',
      upload.sub_path,
      expiry
    )
  end

  def initialize_chunked_upload(upload)
    return # nothing to do in swift
  end

  def chunk_max_reached?(chunk)
    chunk.chunked_upload.chunks.count >= chunk_max_number
  end

  def max_chunked_upload_size
    chunk_max_number * chunk_max_size_bytes
  end

  def max_upload_size
    chunk_max_size_bytes
  end

  def suggested_minimum_chunk_size(upload)
    (upload.size.to_f / chunk_max_number).ceil
  end

  def verify_upload_integrity(upload)
    raise("#{upload} is not a NonChunkedUpload") unless upload.is_a? NonChunkedUpload
    meta = get_object_metadata(upload.storage_container, upload.id) ||
      raise(IntegrityException, "NonChunkedUpload not found in object store")
    if meta["content_length"].to_i != upload.size
      raise IntegrityException, "reported size does not match size computed by StorageProvider"
    elsif upload.fingerprints.none? {|f| meta["etag"] == f.value}
      raise IntegrityException, "reported hash value does not match size computed by StorageProvider"
    end
  end

  def complete_chunked_upload(upload)
    raise("#{upload} is not a ChunkedUpload") unless upload.is_a? ChunkedUpload
    begin
      put_object_manifest(
        upload.storage_container,
        upload.id,
        upload.manifest,
        upload.content_type,
        upload.name
      )
    rescue StorageProviderException => e
      if e.message.match(/.*Etag.*Mismatch.*/)
        raise IntegrityException, 'reported chunk hash does not match that computed by StorageProvider'
      else
        raise e
      end
    end
    meta = get_object_metadata(
      upload.storage_container,
      upload.id
    )
    unless meta["content-length"].to_i == upload.size
      raise IntegrityException, "reported size does not match size computed by StorageProvider"
    end
  end

  def is_complete_chunked_upload?(upload)
    return true if get_object_metadata(upload.storage_container, upload.id)
  end

  def chunk_upload_ready?(upload)
    true
  end

  def chunk_upload_url(chunk)
    build_signed_url(
      'PUT',
      chunk.sub_path,
      expiry
    )
  end

  def download_url(upload,filename=nil)
    filename ||= upload.name
    build_signed_url(
      'GET',
      upload.sub_path,
      expiry,
      filename
    )
  end

  def purge(object)
    raise "#{object} is not purgable" unless object.is_a?(ChunkedUpload) || object.is_a?(Chunk)
    begin
      if object.is_a? ChunkedUpload
        delete_object_manifest(object.storage_container, object.id)
      else
        delete_object(object.storage_container, object.object_path)
      end
    rescue StorageProviderException => e
      unless e.message.match /Not Found/
        raise e
      end
    end
  end

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
    return [] if resp.response.code.to_i == 404
    ([200,204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
    return resp.body ? resp.body.split("\n") : []
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
    return [] if resp.response.code.to_i == 404
    ([200,204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
     return resp.body ? resp.body.split("\n") : []
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

  def get_object_metadata(container, object)
    resp = HTTParty.head(
      "#{storage_url}/#{container}/#{object}",
      headers: auth_header
    )
    return if resp.response.code.to_i == 404
    ([200,204].include?(resp.response.code.to_i)) ||
      raise(StorageProviderException, resp.body)
     resp.headers
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
