module JobTransactionable
  extend ActiveSupport::Concern

  included do
    attr_accessor :current_transaction
    has_many :job_transactions, as: :transactionable
    before_create :root_create_transaction
    before_update :root_update_transaction
    before_destroy :root_destroy_transaction
    after_touch :root_update_transaction
  end

  def create_transaction(state)
    @current_transaction = job_transactions.build(
      request_id: current_transaction ? current_transaction.request_id : ApplicationAudit.generate_current_request_uuid,
      key: self.class.name,
      state: state
    )
  end

  def root_create_transaction
    create_transaction 'created'
  end

  def root_update_transaction
    create_transaction 'updated'
  end

  def root_destroy_transaction
    create_transaction 'destroyed'
    @current_transaction.save
    @current_transaction
  end
end
