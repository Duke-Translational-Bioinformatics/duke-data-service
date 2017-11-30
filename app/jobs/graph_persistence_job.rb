class GraphPersistenceJob < ApplicationJob
  queue_as :graph_persistence

  def perform(job_transaction, graph_model_class_name, action:, graph_hash:, attributes: {})
    self.class.start_job job_transaction

    graph_model_class = graph_model_class_name.constantize

    if action == 'create'
      graph_model_class.create_with_graph_hash(graph_hash)
    elsif action == 'delete'
      graph_model_object = graph_model_class.find_by_graph_hash(graph_hash)
      graph_model_object.destroy
    elsif action == 'update'
      graph_model_object = graph_model_class.find_by_graph_hash(graph_hash)
      graph_model_object.update(attributes)
    end

    self.class.complete_job job_transaction
  end
end
