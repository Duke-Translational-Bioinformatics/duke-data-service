class S3StorageProvider < StorageProvider
  validates :url_root, presence: true, format: { with: /\Ahttps?:\/\// }
  validates :service_user, presence: true
  validates :service_pass, presence: true

  S3_PART_MAX_NUMBER = 10_000
  S3_PART_MAX_SIZE = 5_368_709_120 # 5GB
  S3_MULTIPART_UPLOAD_MAX_SIZE = 5_497_558_138_880 # 5TB
  S3_UPLOAD_MAX_SIZE = 5_368_709_120 # 5GB

  def configure
    # Nothing to configure
    true
  end

  def is_ready?
    begin
      !!list_buckets
    rescue StorageProviderException
      false
    end
  end

  def initialize_project(project)
    create_bucket(project.id)[:location]
  end

  def is_initialized?(project)
    head_bucket(project.id)
  end

  def single_file_upload_url(upload)
    if upload.is_a? NonChunkedUpload
      presigned_url(
        :put_object,
        bucket_name: upload.storage_container,
        object_key: upload.id,
        content_length: upload.size
      ).sub(url_root, '')
    else
      raise("#{upload} is not a NonChunkedUpload")
    end
  end

  def initialize_chunked_upload(upload)
    if upload.is_a? ChunkedUpload
      resp = create_multipart_upload(upload.project.id, upload.id)
      upload.update_attribute(:multipart_upload_id, resp)
    else
      raise "#{upload} is not a ChunkedUpload"
    end
  end

  def chunk_max_reached?(chunk)
    chunk.number > chunk_max_number
  end

  def minimum_chunk_number
    1
  end

  def chunk_max_number
    S3_PART_MAX_NUMBER
  end

  def chunk_max_size_bytes
    S3_PART_MAX_SIZE
  end

  def max_chunked_upload_size
    S3_MULTIPART_UPLOAD_MAX_SIZE
  end

  def max_upload_size
    S3_UPLOAD_MAX_SIZE
  end

  def suggested_minimum_chunk_size(upload)
    (upload.size.to_f / chunk_max_number).ceil
  end

  def verify_upload_integrity(upload)
    raise("#{upload} is not a NonChunkedUpload") unless upload.is_a? NonChunkedUpload
    meta = head_object(upload.storage_container, upload.id) ||
      raise(IntegrityException, "NonChunkedUpload not found in object store")
    if meta[:content_length] != upload.size
      raise IntegrityException, "reported size does not match size computed by StorageProvider"
    elsif upload.fingerprints.none? {|f| meta[:etag] == '"'+f.value+'"'}
      raise IntegrityException, "reported hash value does not match size computed by StorageProvider"
    end
  end

  def complete_chunked_upload(upload)
    raise("#{upload} is not a ChunkedUpload") unless upload.is_a? ChunkedUpload
    parts = upload.chunks.reorder(:number).collect do |chunk|
      { etag: "\"#{chunk.fingerprint_value}\"", part_number: chunk.number }
    end
    begin
      complete_multipart_upload(
        upload.storage_container,
        upload.id,
        upload_id: upload.multipart_upload_id,
        parts: parts
      )
    rescue StorageProviderException => e
      raise(IntegrityException, e.message)
    end
    meta = head_object(upload.storage_container, upload.id)
    unless meta[:content_length] == upload.size
      raise IntegrityException, "reported size does not match size computed by StorageProvider"
    end
  end

  def is_complete_chunked_upload?(upload)
    head_object(upload.storage_container, upload.id)
  end

  def chunk_upload_ready?(upload)
    !!upload.multipart_upload_id
  end

  def chunk_upload_url(chunk)
    begin
      presigned_url(
        :upload_part,
        bucket_name: chunk.chunked_upload.storage_container,
        object_key: chunk.chunked_upload.id,
        upload_id: chunk.chunked_upload.multipart_upload_id,
        part_number: chunk.number,
        content_length: chunk.size
      ).sub(url_root, '')
    rescue ArgumentError
      raise StorageProviderException, 'Upload is not ready'
    end
  end

  def download_url(upload, filename=nil)
    params = {
      bucket_name: upload.storage_container,
      object_key: upload.id
    }
    params[:response_content_disposition] = 'attachment; filename='+filename if filename
    presigned_url(
      :get_object,
      **params
    ).sub(url_root, '')
  end

  def purge(object)
    if object.is_a? Upload
      delete_object(object.storage_container, object.id)
    elsif object.is_a? Chunk
      true
    else
      raise "#{object} is not purgable"
    end
  end

  # S3 Interface
  def client
    @client ||= Aws::S3::Client.new(
      region: 'us-east-1',
      force_path_style: force_path_style.nil? || force_path_style,
      access_key_id: service_user,
      secret_access_key: service_pass,
      endpoint: url_root
    )
  end

  def list_buckets
    begin
      client.list_buckets.to_h[:buckets]
    rescue Aws::Errors::ServiceError => e
      raise(StorageProviderException, e.message)
    end
  end

  def create_bucket(bucket_name)
    begin
      client.create_bucket(bucket: bucket_name).to_h
    rescue Aws::Errors::ServiceError => e
      raise(StorageProviderException, e.message)
    end
  end

  def head_bucket(bucket_name)
    begin
      client.head_bucket(bucket: bucket_name).to_h
    rescue Aws::S3::Errors::NoSuchBucket
      false
    rescue Aws::Errors::ServiceError => e
      raise(StorageProviderException, e.message)
    end
  end

  def head_object(bucket_name, object_key)
    begin
      client.head_object(bucket: bucket_name, key: object_key).to_h
    rescue Aws::S3::Errors::NoSuchKey
      false
    rescue Aws::Errors::ServiceError => e
      raise(StorageProviderException, e.message)
    end
  end

  def create_multipart_upload(bucket_name, object_key)
    begin
      client.create_multipart_upload(bucket: bucket_name, key: object_key).upload_id
    rescue Aws::Errors::ServiceError => e
      raise(StorageProviderException, e.message)
    end
  end

  def complete_multipart_upload(bucket_name, object_key, upload_id:, parts:)
    begin
      resp = client.complete_multipart_upload(bucket: bucket_name, key: object_key, upload_id: upload_id, multipart_upload: { parts: parts })
    rescue Aws::Errors::ServiceError => e
      raise(StorageProviderException, e.message)
    end
    resp.to_h
  end

  def delete_object(bucket_name, object_key)
    begin
      client.delete_object(bucket: bucket_name, key: object_key).to_h
    rescue Aws::Errors::ServiceError => e
      raise(StorageProviderException, e.message)
    end
  end

  def presigned_url(method, bucket_name:, object_key:, **params)
    @signer ||= Aws::S3::Presigner.new(client: client)
    @signer.presigned_url(method, bucket: bucket_name, key: object_key, expires_in: signed_url_duration, **params)
  end
end
