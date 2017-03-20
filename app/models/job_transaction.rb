class JobTransaction < ActiveRecord::Base
  belongs_to :transactionable, polymorphic: true
  validates :transactionable, presence: true
  validates :key, presence: true, uniqueness: {scope: :transactionable_id, case_sensitive: false}
  validates :state, presence: true
end
