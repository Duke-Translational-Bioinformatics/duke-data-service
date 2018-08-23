class Fingerprint < ActiveRecord::Base
  audited
  belongs_to :upload

  validates :upload_id, presence: true
  validates :value, presence: true
  validates :algorithm, presence: true, inclusion: {in: :available_algorithms}

  def available_algorithms
    %w{md5 sha256 sha1}
  end
end
