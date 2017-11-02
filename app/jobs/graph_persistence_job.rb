class GraphPersistenceJob < ApplicationJob
  queue_as :graph_persistence

  def perform(job_transaction, graphed_object, action:)
    self.class.start_job job_transaction

    if action == 'create'
      graphed_object.graph_create
    end

    self.class.complete_job job_transaction
  end
end
