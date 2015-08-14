class Chunk < ActiveRecord::Base
  belongs_to :upload

  validates :upload_id, presence: true
  validates :number, presence: true
  validates :size, presence: true
  validates :fingerprint_value, presence: true
  validates :fingerprint_algorithm, presence: true

  def http_verb
    'PUT'
  end

  def host
    upload.storage_provider.url_root
  end

  def http_headers
    []
  end

  def url
    @url ||= upload.storage_provider.get_signed_url(self)
  end
end
