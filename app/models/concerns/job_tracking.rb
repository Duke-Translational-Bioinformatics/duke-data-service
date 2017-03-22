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

    def self.start_job(transaction)
      transaction.update(state: 'in progress')
    end

    def self.complete_job(transaction)
      transaction.update(state: 'complete')
    end
  end
end
