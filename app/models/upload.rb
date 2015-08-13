class Upload < ActiveRecord::Base
  belongs_to :project
  belongs_to :storage_provider
  has_many :chunks

  validates :name, presence: true

  def temporary_url
    storage_provider.get_signed_url(self)
  end

  def create_manifest
    storage_provider.create_slo_manifest(self)
  end
end
