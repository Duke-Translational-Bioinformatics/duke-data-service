class JobTransaction < ActiveRecord::Base
  belongs_to :transactionable, polymorphic: true
  validates :transactionable, presence: true
  validates :key, presence: true
  validates :state, presence: true
end
