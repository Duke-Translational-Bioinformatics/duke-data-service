class FileVersion < ActiveRecord::Base
  include Kinded
  include Graphed
  after_create :graph_node
  after_save :delete_graph_node

  audited
  belongs_to :data_file
  belongs_to :upload
  has_many :project_permissions, through: :data_file

  validates :upload_id, presence: true, unless: :is_deleted

  before_create :set_version_number

  delegate :name, to: :data_file
  delegate :http_verb, to: :upload

  def host
    upload.url_root
  end

  def url
    upload.temporary_url(name)
  end

  def next_version_number
    max_version = data_file.file_versions.maximum(:version_number) || 0
    max_version + 1
  end

  def set_version_number
    self.version_number = next_version_number unless persisted?
    self.version_number
  end

  def kind
    super('file-version')
  end

  def delete_graph_node
    super(true)
  end
end
