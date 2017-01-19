# AttributedtoProvRelation is a ProvRelation through Single Table inheritance

class AttributedToProvRelation < ProvRelation
  def kind
    'dds-was-attributed-to'
  end
end
