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

  def self.delete_all_complete_by_request_id
    created_before = Time.now
    where(request_id: select(:request_id).where(state: 'complete')).where('created_at < ?', created_before).delete_all
  end

#months_ago = ((Time.now - j.created_at) / 1.month).floor
#months_ago.downto(2).each do |m|
#  del_num = JobTransaction.where(request_id: JobTransaction.select(:request_id).where(state: 'complete')).where('created_at < ?', Time.now - m.months).delete_all
#  puts "deleted #{del_num} from #{m} months ago"
#end
end
