class JobTransaction < ActiveRecord::Base
  belongs_to :transactionable, polymorphic: true
  validates :transactionable_id, presence: true
  validates :transactionable_type, presence: true
  validates :key, presence: true
  validates :request_id, presence: true
  validates :state, presence: true
  scope :orphans, -> { where(request_id: select(:request_id).group(:request_id).having('count(*) = 1')) }

  def self.oldest_completed_at
    reorder(:created_at).where(state: 'complete').first&.created_at
  end

  def self.oldest_orphan_created_at
    orphans.reorder(:created_at).first&.created_at
  end

  def self.delete_all_complete_jobs(created_before: Time.now)
    where('(transactionable_type, transactionable_id, request_id, key) in (?)', select(:transactionable_type, :transactionable_id, :request_id, :key).where(state: 'complete').where('created_at < ?', created_before)).delete_all
  end

  def self.delete_all_orphans(created_before: Time.now)
    orphans.where('created_at < ?', created_before).delete_all
  end
end
