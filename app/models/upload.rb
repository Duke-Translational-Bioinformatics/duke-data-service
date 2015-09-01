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

  def sub_path 
    [project_id, id].join('/')
  end

  def temporary_url
    http_verb = 'GET'
    expiry = updated_at.to_i + storage_provider.signed_url_duration
    storage_provider.build_signed_url(http_verb, sub_path, expiry)
  end

  def manifest
    chunks.collect do |chunk|
      {
        path: chunk.sub_path, 
        etag: chunk.fingerprint_value,
        size_bytes: chunk.size
      }
    end
  end

  def complete
    storage_provider.put_object_manifest(project_id, id, manifest)
  end

  def create_manifest
    storage_provider.create_slo_manifest(self)
  end
end
