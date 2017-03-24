module JobTracking
  extend ActiveSupport::Concern

  included do
    def self.transaction_key
      self.class.name
    end

    def self.initialize_job(transactionable)
      raise ArgumentError.new("object is not job_transactionable") unless transactionable.class.include?(JobTransactionable)
      JobTransaction.create(
        transactionable: transactionable,
        request_id: transactionable.current_transaction.request_id,
        key: self.transaction_key,
        state: 'initialized'
      )
    end

    def self.start_job(initial_transaction)
      initial_transaction.transactionable
      .job_transactions
      .create(
        key: initial_transaction.key,
        request_id: initial_transaction.request_id,
        state: 'in progress'
      )
    end

    def self.complete_job(initial_transaction)
      initial_transaction.transactionable
      .job_transactions
      .create(
        key: initial_transaction.key,
        request_id: initial_transaction.request_id,
        state: 'complete'
      )
    end
  end
end