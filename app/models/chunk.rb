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
    storage_provider.url_root
  end

  def http_headers
    []
  end

  def sub_path
    [project_id, upload_id, number].join('/')
  end

  def expiry
    updated_at.to_i + storage_provider.chunk_duration
  end

  def url
    storage_provider.build_signed_url(http_verb, sub_path, expiry)
  end
end
