# AttributedtoProvRelation is a ProvRelation through Single Table inheritance

class AssociatedWithProvRelation < ProvRelation
  def kind
    'dds-relation-was-associated-with'
  end
end
