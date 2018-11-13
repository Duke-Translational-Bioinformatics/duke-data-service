class FileVersion < ActiveRecord::Base
  include Kinded
  include Graphed::Node
  include JobTransactionable
  include Restorable
  include Purgable

  after_save :logically_delete_graph_node
  around_update :manage_purge_and_restore

  audited
  belongs_to :data_file
  alias parent data_file
  alias deleted_from_parent data_file

  belongs_to :upload
  has_many :project_permissions, through: :data_file

  validates :upload_id, presence: true, immutable: true, unless: :is_deleted
  validates :is_deleted,
    absence: { message: 'The current file version cannot be deleted.' },
    unless: :deletion_allowed?
  validates :is_purged,
    absence: { message: 'The current file version cannot be purged.' },
    unless: :purge_allowed?

  validates_each :upload_id, on: :create do |record, attr, value|
    if record.upload_id
      if record.upload_id == record.data_file.file_versions.order(:version_number).last&.upload_id
        record.errors.add(attr, 'match current file version.')
      end
    end
  end

  before_create :set_version_number

  delegate :name, to: :data_file
  delegate :http_verb, to: :upload

  def host
    upload.endpoint
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

  def purge_allowed?
    self.version_number != current_version_number ||
      data_file.is_purged?
  end

  def kind
    super('file-version')
  end

  def manage_purge_and_restore
    newly_restored = is_deleted_changed? && is_deleted_was && !is_deleted?
    newly_purged = is_purged_changed? && is_purged
    yield

    if newly_restored
      if data_file.is_deleted?
        data_file.update(is_deleted: false)
      end
    elsif newly_purged
      UploadStorageRemovalJob.perform_later(
        UploadStorageRemovalJob.initialize_job(self),
        upload.id
      )
    #else not needed
    end
  end

  def purge
    raise UnPurgableException.new(kind)
  end

  private

  def current_version_number
    data_file.file_versions.maximum(:version_number) || 0
  end
end
