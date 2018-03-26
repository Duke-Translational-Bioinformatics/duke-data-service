# AttributedtoProvRelation is a ProvRelation through Single Table inheritance

class AttributedToProvRelation < ProvRelation
  def kind
    'dds-relation-was-attributed-to'
  end

  def graph_model_name
    'WasAttributedTo'
  end
end
