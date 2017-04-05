module S3StorageProvider
  # TODO(cedric): This doesn't seem to work. Must be missing detail of module/class/mixin instance method creation
  # Maybe set @@S3 = get_s3_client?
  def self.included(base)
      # When module is used as mixin, create an S3 client for instantiated class to use
      self.S3 = get_s3_client
  end

  def register_keys
    # This method doesn't do anything. It's just here for compatibility between Swift/S3
    # Storage Provider calls.
    true
  end

  def signed_url_duration
    60*5 # 5 minutes
  end

  def build_signed_url(http_verb, sub_path, expiry=signed_url_duration, filename=nil)
    # Return a signed URL for the given S3 object
    # sub_path = [project_id, object_path].join('/')
    #
    # Example of object_path:
    # object_path = [upload_id, chunk_number].join('/')
    #
    # NOTE(cedric): It doesn't look like we currently need 'filename' parameter. I
    # am keeping it here so that the method calls look identical between S3/Swift for
    # build_signed_url
    verb_symbol_map = {
        'GET'       =>    :get,
        # AWS has a 5GB limit on files uploaded with single PUT operation
        'PUT'       =>    :put,
        'HEAD'      =>   :head,
        'DELETE'    => :delete,
    }

    if not verb_symbol_map.has_key?(http_verb)
        # TODO(cedric): Maybe this exception class should be different?
        raise(StorageProviderException, 'Unknown HTTP VERB: ' + http_verb)
    end

    # NOTE(cedric): chunk.rb will hand StorageProvider a one-month expiry. It looks like:
    # * it hands us an expiry epoch timestamp, not the number of seconds until expiry
    # * the AWS library maximum is 1 week
    #
    # We'll need to apply the AWS max if it's larger than 1 week, epoch value or not.
    aws_expiry_max_seconds = 604800
    if expiry > aws_expiry_max_seconds
        expiry = aws_expiry_max_seconds
    end

    # Unpack string params from a format meant for Swift API
    path_fragments = sub_path.split('/')
    bucket = path_fragments[0]
    key = path_fragments[1..-1].join('/')

    object = Aws::S3::Object.new(bucket_name: bucket, key: key, client: get_s3_client)
    object.presigned_url(verb_symbol_map[http_verb], expires_in: expiry)
  end

  def get_account_info
    # TODO(cedric): This may require a client & call to AWS STS
    logger.error('S3StorageProvider.get_account_info is not implemented, sorry~')
    true
  end

  def get_containers
    # Return a list of bucket names
    # NOTE(cedric): Named to match Swift methods. Equivalent S3 name would be: list_buckets
    get_s3_client.list_buckets.buckets.map {|b| b.name}
  end

  def get_container_meta(name)
    # NOTE(cedric): Named to match Swift methods
    logger.error('S3StorageProvider.get_container_meta is not implemented, sorry~')
    true
  end

  def get_container_objects(name)
    # Return a list of bucket objects (up to 1000, or default non-paginating maximum)
    # NOTE(cedric): Named to match Swift methods. Equivalent S3 name would be: list_bucket_objects
    get_s3_client.list_objects_v2(bucket: name).contents
    true
  end

  def put_container(name)
    # NOTE(cedric): Named to match Swift methods. Equivalent S3 name would be: create_bucket
    get_s3_client.create_bucket(bucket: name)
    true
  end

  def delete_container(name)
    # NOTE(cedric): Named to match Swift methods. Equivalent S3 name would be: delete_bucket
    get_s3_client.delete_bucket(bucket: name)
    true
  end

  def put_object(bucket, key, body, content_type=nil, content_disposition=nil)
    put_options = {bucket: bucket, key: key, body: body}
    put_options[:content_type] = content_type if not content_type.nil?
    put_options[:content_disposition] = content_disposition if not content_disposition.nil?
    # NOTE(cedric): :body can be a string or file/io object
    get_s3_client.put_object(put_options)
    true
  end

  def put_object_manifest(bucket, key, manifest, content_type=nil, filename=nil)
      logger.error('S3StorageProvider.put_object_manifest is not implemented, sorry~')
      true
  end

  def delete_object_manifest(bucket, key)
      logger.error('S3StorageProvider.delete_object_manifest is not implemented, sorry~')
      true
  end

  def delete_object(bucket, key)
      get_s3_client.delete_object(bucket: bucket, key: key)
      true
  end

  def get_object_metadata(bucket, key)
    begin
      object = Aws::S3::Object.new(bucket_name: bucket, key: key, client: get_s3_client)
      # NOTE(cedric): In Swift this returns a dict with keys:
      # content-length
      # etag
      # last-modified
      # x-timestamp
      # x-object-meta-orig-filename
      # content-type
      # x-trans-id
      # x-openstack-request-id
      #
      # In swift these are derived from a response header, are lower-cased, and then checked in upload.rb.
      # We'll attempt to provide the equivalent:
      object_meta = {"storage class"        => obj.storage_class,
                     "replication status"   => obj.replication_status,
                     "etag"                 => obj.etag.tr('"', '').tr("'", ''),
                     "content-type"         => obj.content_type,
                     "content-length"       => obj.content_length,
                     "accept-ranges"        => obj.accept_ranges}
    rescue Aws::S3::Errors::ServiceError => e
      # Convert to StorageProviderException, so that upload.rb catches it.
      # TODO(cedric): Why doesn't upload.rb have a catch-all exception handler?
      raise(StorageProviderException, e.message)
    end
    object_meta
  end

  # TODO(cedric): Does setting this as private in the module affect its 'include' in StorageProvider?
  # TODO(cedric): Should parameters for the S3 client be passed into the StorageProvider
  # ActiveRecord?
  def get_s3_client
    # Return an S3 client.
    s3_options = {}
    if Aws.shared_config.credentials.nil?
      s3_options[:access_key_id] = ENV['S3_ACCESS_KEY_ID']
      s3_options[:secret_access_key] = ENV['S3_SECRET_ACCESS_KEY']
    end

    if (ENV['S3_ENDPOINT'].nil? or ENV['S3_ENDPOINT'].empty?) and Aws.shared_config.region.nil?
      s3_options[:region] = ENV['S3_REGION']
    else
      s3_options[:endpoint] = ENV['S3_ENDPOINT']
    end
    Aws::S3::Client.new(s3_options)
  end
end

module SwiftStorageProvider
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

class StorageProvider < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  validates :display_name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :name, presence: true
  validates :storage_type, presence: true, inclusion: {in: %w(swift s3)}
  # TODO(cedric): Maybe use a custom ActiveModel::Validator class and validates_with,
  # to do conditional validation of options, depending on if storage_type is swift or s3
  #
  # Swift options (should be renamed to have swift_ in front of them?):
  #validates :url_root, presence: true
  #validates :provider_version, presence: true
  #validates :auth_uri, presence: true
  #validates :service_user, presence: true
  #validates :service_pass, presence: true
  #validates :primary_key, presence: true
  #validates :secondary_key, presence: true
  #
  # S3 options:
  #s3 access key id
  #s3 secret access key
  #s3 endpoint
  #s3 region (used if endpoint isn't specified)

  # This loads the instance methods appropriate for the given storage provider
  after_initialize :mixin_provider

  def mixin_provider
    if storage_type == 'swift'
        extend SwiftStorageProvider
    elsif storage_type == 's3'
        extend S3StorageProvider
    else
      raise(StorageProviderException, 'Unknown storage provider: ' + storage_type)
    end
  end
end
