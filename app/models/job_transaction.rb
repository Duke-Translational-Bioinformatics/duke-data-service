class JobTransaction < ActiveRecord::Base
  belongs_to :transactionable, polymorphic: true
  validates :transactionable_id, presence: true
  validates :transactionable_type, presence: true
  validates :key, presence: true
  validates :request_id, presence: true
  validates :state, presence: true

  def self.oldest_completed_at
    unscope(:order).order(:created_at).where(state: 'complete').first&.created_at
  end

  def self.delete_all_complete_by_request_id(created_before: Time.now)
    where(request_id: select(:request_id).where(state: 'complete').where('created_at < ?', created_before)).delete_all
  end

  def self.delete_all_orphans(created_before: Time.now)
    #delete from job_transactions where request_id in (select request_id from job_transactions group by request_id having count(*) = 1);
    where(request_id: select(:request_id).group(:request_id).having('count(*) = 1')).where('created_at < ?', created_before).delete_all
  end
end
