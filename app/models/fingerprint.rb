class Fingerprint < ActiveRecord::Base
  audited
  belongs_to :upload

  validates :upload_id, presence: true
  validates :value, presence: true
  validates :algorithm, presence: true
end
