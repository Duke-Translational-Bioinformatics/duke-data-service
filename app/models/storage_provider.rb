class StorageProvider < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  validates :display_name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :name, presence: true
  validates :is_default, uniqueness: true, if: :is_default
  validates :is_deprecated, inclusion: {
    in: [false],
    message: "The Default StorageProvider cannot be deprecated!"
  }, if: :is_default

  def self.default
    find_by(is_default: true)
  end

  ### Interface Methods
  def signed_url_duration
    60*5 # 5 minutes
  end

  def expiry
    Time.now.to_i + signed_url_duration
  end

  def initialize_project(project)
    raise NotImplementedError.new("You must implement initialize_project.")
  end

  def single_file_upload_url(upload)
    raise NotImplementedError.new("You must implement single_file_upload_url.")
  end

  def initialize_chunked_upload(upload)
    raise NotImplementedError.new("You must implement initialize_chunked_upload.")
  end

  def endpoint
    raise NotImplementedError.new("You must implement endpoint.")
  end

  def chunk_upload_url(chunk)
    raise NotImplementedError.new("You must implement chunk_upload_url.")
  end

  def chunk_max_exceeded?(chunk)
    raise NotImplementedError.new("You must implement chunk_max_exceeded?.")
  end

  def max_chunked_upload_size
    raise NotImplementedError.new("You must implement max_chunked_upload_size.")
  end

  def suggested_minimum_chunk_size(upload)
    raise NotImplementedError.new("You must implement suggested_minimum_chunk_size.")
  end

  def complete_chunked_upload(upload)
    raise NotImplementedError.new("You must implement complete_chunked_upload.")
  end

  def download_url(upload,filename=nil)
    raise NotImplementedError.new("You must implement download_url.")
  end

  def purge(upload)
    raise NotImplementedError.new("You must implement purge.")
  end
end
