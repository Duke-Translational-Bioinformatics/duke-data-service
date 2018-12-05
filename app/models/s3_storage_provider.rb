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
  end

  def is_initialized?(project)
  end

  def single_file_upload_url(upload)
  end

  def initialize_chunked_upload(upload)
  end

  def endpoint
  end

  def chunk_max_reached?(chunk)
  end

  def max_chunked_upload_size
  end

  def suggested_minimum_chunk_size(upload)
  end

  def complete_chunked_upload(upload)
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

  def create_multipart_upload(bucket, object_key)
  end

  def complete_multipart_upload(bucket, object_key, upload_id:, parts:)
  end

  def presigned_url(method, bucket:, object_key:, **params)
  end
end
