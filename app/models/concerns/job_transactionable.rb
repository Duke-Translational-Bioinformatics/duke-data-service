module JobTransactionable
  extend ActiveSupport::Concern

  included do
    has_many :job_transactions, foreign_key: "transactionable_id"
  end

  def job_transactionable?
    true
  end
end