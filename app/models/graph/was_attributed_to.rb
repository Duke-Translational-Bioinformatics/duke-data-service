class Graph::WasAttributedTo
  include Graphed::RelModel

  property :model_id
  property :model_kind
  from_class 'Graph::FileVersion'
  type 'WasAttributedTo'
  to_class 'Graph::Agent'
  creates_unique
end
