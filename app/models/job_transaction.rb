class JobTransaction < ApplicationRecord
  belongs_to :transactionable, polymorphic: true
  validates :transactionable_id, presence: true
  validates :transactionable_type, presence: true
  validates :key, presence: true
  validates :request_id, presence: true
  validates :state, presence: true
  scope :orphans, ->(limit: nil) { where(request_id: orphan_request_ids(limit: limit)) }
  scope :logical_orphans, -> { where(arel_table[:request_id].in(logical_orphan_request_ids)) }

  def self.initial_states
    ['updated', 'created', 'trashbin_migration']
  end

  def self.logical_orphan_request_ids
    requests_without_orphans = select(:request_id).where.not(state: initial_states)
    arel_table.project(arel_table[:request_id]).except(requests_without_orphans)
  end

  def self.orphan_request_ids(limit: nil)
    ids = select(:request_id).group(:request_id).having('count(*) = 1').order('min(created_at)')
    ids = ids.limit(limit) if limit
    ids
  end

  def self.oldest_completed_at
    reorder(:created_at).where(state: 'complete').first&.created_at
  end

  def self.oldest_orphan_created_at
    orphans.reorder(:created_at).first&.created_at
  end

  def self.oldest_logical_orphan_created_at
    logical_orphans.reorder(:created_at).first&.created_at
  end

  def self.delete_all_complete_jobs(created_before: Time.now)
    where('(transactionable_type, transactionable_id, request_id, key) in (?)', select(:transactionable_type, :transactionable_id, :request_id, :key).where(state: 'complete').where('created_at < ?', created_before)).delete_all
  end

  def self.delete_all_orphans(created_before: Time.now, limit: nil)
    orphans(limit: limit).where('created_at < ?', created_before).delete_all
  end

  def self.delete_all_logical_orphans(created_before: Time.now)
    logical_orphans.where('created_at < ?', created_before).delete_all
  end
end
