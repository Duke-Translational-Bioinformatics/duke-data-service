class ProvRelation < ActiveRecord::Base
 default_scope { order('created_at DESC') }
 include Kinded
 include Graphed
 after_create :create_graph_relation
 after_destroy :delete_graph_relation

  audited

  validates :creator_id, presence: true
  validates :relatable_from, presence: true
  validates :relationship_type, presence: true
  validates :relatable_to, presence: true

  belongs_to :creator, class_name: "User"
  belongs_to :relatable_from, polymorphic: true
  belongs_to :relatable_to, polymorphic: true

  def kind
    super("relation-#{ relationship_type }")
  end

  def create_graph_relation
    super(
      relationship_type.split('-').map{|part| part.capitalize}.join(''),
      relatable_from,
      relatable_to
    )
  end

  def graph_relation
    super(
      relationship_type.split('-').map{|part| part.capitalize}.join(''),
      relatable_from,
      relatable_to
    )
  end
end
