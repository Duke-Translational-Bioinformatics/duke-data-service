class S3StorageProvider < StorageProvider
  validates :url_root, presence: true, format: { with: /\Ahttps?:\/\// }
  validates :service_user, presence: true
  validates :service_pass, presence: true

  def configure
    # Nothing to configure
    true
  end

  def is_ready?
  end

  def initialize_project(project)
    create_bucket(project.id)[:location]
  end

  def is_initialized?(project)
    head_bucket(project.id)
  end

  def single_file_upload_url(upload)
  end

  def initialize_chunked_upload(upload)
    resp = create_multipart_upload(upload.project.id, upload.id)
    upload.update_attribute(:multipart_upload_id, resp[:upload_id])
  end

  def chunk_max_reached?(chunk)
    chunk.number > chunk_max_number
  end

  def max_chunked_upload_size
    9223372036854775807 # max value for 8 byte signed integer
  end

  def suggested_minimum_chunk_size(upload)
    (upload.size.to_f / chunk_max_number).ceil
  end

  def complete_chunked_upload(upload)
    parts = upload.chunks.reorder(:number).collect do |chunk|
      { etag: "\"#{chunk.fingerprint_value}\"", part_number: chunk.number }
    end
    complete_multipart_upload(
      upload.storage_container,
      upload.id,
      upload_id: upload.multipart_upload_id,
      parts: parts
    )
    meta = head_object(upload.storage_container, upload.id)
    unless meta[:content_length] == upload.size
      raise IntegrityException, "reported size does not match size computed by StorageProvider"
    end
  end

  def is_complete_chunked_upload?(upload)
  end

  def chunk_upload_url(chunk)
  end

  def download_url(upload, filename=nil)
  end

  def purge(object)
  end

  # S3 Interface
  def client
    @client ||= Aws::S3::Client.new(
      region: 'us-east-1',
      force_path_style: true,
      access_key_id: service_user,
      secret_access_key: service_pass,
      endpoint: url_root
    )
  end

  def list_buckets
    client.list_buckets.to_h[:buckets]
  end

  def create_bucket(bucket_name)
    client.create_bucket(bucket: bucket_name).to_h
  end

  def head_bucket(bucket_name)
    begin
      client.head_bucket(bucket: bucket_name).to_h
    rescue Aws::S3::Errors::NoSuchBucket
      false
    end
  end

  def head_object(bucket_name, object_key)
    begin
      client.head_object(bucket: bucket_name, key: object_key).to_h
    rescue Aws::S3::Errors::NoSuchKey
      false
    end
  end

  def create_multipart_upload(bucket_name, object_key)
    client.create_multipart_upload(bucket: bucket_name, key: object_key).upload_id
  end

  def complete_multipart_upload(bucket_name, object_key, upload_id:, parts:)
    begin
      resp = client.complete_multipart_upload(bucket: bucket_name, key: object_key, upload_id: upload_id, multipart_upload: { parts: parts })
    rescue => e
      raise(StorageProviderException, e.message)
    end
    resp.to_h
  end

  def presigned_url(method, bucket_name:, object_key:, **params)
    @signer ||= Aws::S3::Presigner.new(client: client)
    @signer.presigned_url(method, bucket: bucket_name, key: object_key, expires_in: signed_url_duration, **params)
  end
end
