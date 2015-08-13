class Chunk < ActiveRecord::Base
  belongs_to :upload

  def temporary_url
    upload.storage_provider.get_signed_url(self, 'PUT')
  end
end
