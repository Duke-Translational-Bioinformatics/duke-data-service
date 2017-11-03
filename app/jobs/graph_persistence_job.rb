class GraphPersistenceJob < ApplicationJob
  queue_as :graph_persistence

  def perform(job_transaction, graph_model_class_name, action:, params: {})
    self.class.start_job job_transaction

    graph_model_class = graph_model_class_name.constantize

    if action == 'create'
      graph_model_class.create(params)
    elsif action == 'delete'
      graph_model_object = graph_model_class.find_by(params)
      graph_model_object.destroy
    end

    self.class.complete_job job_transaction
  end
end
