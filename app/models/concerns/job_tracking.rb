module JobTracking
  extend ActiveSupport::Concern

  included do
    def self.transaction_key
      self.class.name
    end

    def self.initialize_job(transactionable)
      raise ArgumentError.new("object is not job_transactionable") unless transactionable.class.include?(JobTransactionable)
      self.register_job_status(
        transactionable.current_transaction,
        'initialized',
        self.transaction_key
      )
    end

    def self.start_job(initial_transaction)
      self.register_job_status(
        initial_transaction,
        'in progress'
      )
    end

    def self.complete_job(initial_transaction)
      self.register_job_status(
        initial_transaction,
        'complete'
      )
    end

    def self.register_job_status(transaction, state, key=nil)
      key = transaction.key unless (key)
      JobTransaction.create(
        transactionable_id: transaction.transactionable_id,
        transactionable_type: transaction.transactionable_type,
        request_id: transaction.request_id,
        key: key,
        state: state
      )
    end
  end
end
