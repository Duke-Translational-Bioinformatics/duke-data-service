class Chunk < ActiveRecord::Base
  belongs_to :upload
  has_one :storage_provider, through: :upload

  validates :upload_id, presence: true
  validates :number, presence: true
  validates :size, presence: true
  validates :fingerprint_value, presence: true
  validates :fingerprint_algorithm, presence: true

  delegate :project_id, to: :upload

  def http_verb
    'PUT'
  end

  def host
    upload.storage_provider.url_root
  end

  def http_headers
    []
  end

  def path
    [storage_provider.root_path, project_id, upload_id, number].join('/')
  end

  def expiry
    updated_at.to_i + storage_provider.chunk_duration
  end

  def hmac_body
    [http_verb, expiry, path].join("\n")
  end

  def signature
    storage_provider.build_signature(hmac_body)
  end

  def url
    URI.encode("#{path}?temp_url_sig=#{signature}&temp_url_expires=#{expiry}")
  end
end
