class JobTransaction < ActiveRecord::Base
  belongs_to :transactionable, polymorphic: true
  validates :transactionable_id, presence: true
  validates :transactionable_type, presence: true
  validates :key, presence: true
  validates :request_id, presence: true
  validates :state, presence: true
end
