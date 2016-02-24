class SoftwareAgent < ActiveRecord::Base
  include SerializedAudit
  audited

  belongs_to :creator, class_name: "User"
  has_one :api_key
  
  validates :name, presence: true, unless: :is_deleted
  validates :creator_id, presence: true, unless: :is_deleted
end
