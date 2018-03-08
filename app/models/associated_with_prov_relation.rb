# AttributedtoProvRelation is a ProvRelation through Single Table inheritance

class AssociatedWithProvRelation < ProvRelation
  def kind
    'dds-relation-was-associated-with'
  end

  def graph_model_name
    'WasAssociatedWith'
  end
end
