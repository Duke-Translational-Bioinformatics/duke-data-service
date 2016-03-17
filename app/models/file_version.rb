class FileVersion < ActiveRecord::Base
  include Kinded

  audited
  belongs_to :data_file
  belongs_to :upload

  validates :upload_id, presence: true, unless: :is_deleted

  delegate :name, to: :data_file
  delegate :http_verb, to: :upload

  def host
    upload.url_root
  end

  def url
    upload.temporary_url(name)
  end

  def kind
    super('file-version')
  end
end
