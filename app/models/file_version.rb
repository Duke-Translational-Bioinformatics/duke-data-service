class FileVersion < ActiveRecord::Base
  include Kinded
  include Graphed
  after_create :create_graph_node
  after_save :logically_delete_graph_node
  after_destroy :delete_graph_node

  audited
  belongs_to :data_file
  belongs_to :upload
  has_many :project_permissions, through: :data_file

  validates :upload_id, presence: true, immutable: true, unless: :is_deleted
  validates :is_deleted, 
    absence: { message: 'The current file version cannot be deleted.' },
    unless: :deletion_allowed?
  validates_each :upload_id, on: :create do |record, attr, value|
    if record.upload_id
      if record.upload_id == record.data_file.current_file_version.upload_id
        record.errors.add(attr, 'match current file version.')
      end
    end
  end

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
    current_version_number + 1
  end

  def set_version_number
    self.version_number = next_version_number unless persisted?
    self.version_number
  end

  def deletion_allowed?
    self.version_number != current_version_number ||
      data_file.is_deleted?
  end

  def kind
    super('file-version')
  end

  private

  def current_version_number
    data_file.file_versions.maximum(:version_number) || 0
  end
end
