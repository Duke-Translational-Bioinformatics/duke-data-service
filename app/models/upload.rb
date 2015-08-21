class Upload < ActiveRecord::Base
  belongs_to :project
  belongs_to :storage_provider
  has_many :chunks

  validates :project_id, presence: true
  validates :name, presence: true
  validates :size, presence: true
  validates :fingerprint_value, presence: true
  validates :fingerprint_algorithm, presence: true
  validates :storage_provider_id, presence: true

  def temporary_url
    http_verb = 'GET'
    sub_path = [project_id, id].join('/')
    expiry = updated_at.to_i + storage_provider.signed_url_duration
    storage_provider.build_signed_url(http_verb, sub_path, expiry)
  end

  def create_manifest
    storage_provider.create_slo_manifest(self)
  end
end
