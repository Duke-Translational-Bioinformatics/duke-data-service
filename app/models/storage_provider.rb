class StorageProvider < ApplicationRecord
  default_scope { order('created_at DESC') }

  has_many :project_storage_providers

  validates :display_name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :name, presence: true
  validates :is_default, uniqueness: true, if: :is_default
  validates :is_deprecated, inclusion: {
    in: [false],
    message: "The Default StorageProvider cannot be deprecated!"
  }, if: :is_default

  after_create :initialize_projects

  def self.default
    find_by(is_default: true)
  end

  def initialize_projects
    Project.all.each do |project|
      project_storage_providers.create(project: project)
    end
  end

  ### Interface Methods
  def minimum_chunk_number
    0
  end

  def fingerprint_algorithm
    'md5'
  end

  def signed_url_duration
    60*5 # 5 minutes
  end

  def expiry
    Time.now.to_i + signed_url_duration
  end

  def configure
    raise NotImplementedError.new("You must implement configure.")
  end

  def is_ready?
    raise NotImplementedError.new("You must implement is_ready?")
  end

  def initialize_project(project)
    raise NotImplementedError.new("You must implement initialize_project.")
  end

  def is_initialized?(project)
    raise NotImplementedError.new("You must implement is_initialized?.")
  end

  def single_file_upload_url(upload)
    raise NotImplementedError.new("You must implement single_file_upload_url.")
  end

  def initialize_chunked_upload(upload)
    raise NotImplementedError.new("You must implement initialize_chunked_upload.")
  end

  def chunk_upload_ready?(upload)
    raise NotImplementedError.new("You must implement chunk_upload_ready?.")
  end

  def chunk_upload_url(chunk)
    raise NotImplementedError.new("You must implement chunk_upload_url.")
  end

  def chunk_max_reached?(chunk)
    raise NotImplementedError.new("You must implement chunk_max_reached?.")
  end

  def max_chunked_upload_size
    raise NotImplementedError.new("You must implement max_chunked_upload_size.")
  end

  def max_upload_size
    raise NotImplementedError.new("You must implement max_upload_size.")
  end

  def suggested_minimum_chunk_size(upload)
    raise NotImplementedError.new("You must implement suggested_minimum_chunk_size.")
  end

  def verify_upload_integrity(upload)
    raise NotImplementedError.new("You must implement verify_upload_integrity.")
  end

  def complete_chunked_upload(upload)
    raise NotImplementedError.new("You must implement complete_chunked_upload.")
  end

  def is_complete_chunked_upload?(upload)
    raise NotImplementedError.new("You must implement is_complete_chunked_upload?.")
  end

  def download_url(upload,filename=nil)
    raise NotImplementedError.new("You must implement download_url.")
  end

  def purge(upload)
    raise NotImplementedError.new("You must implement purge.")
  end
end
