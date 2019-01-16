class ProvRelation < ApplicationRecord
  default_scope { order('created_at DESC') }
  before_validation :set_relationship_type

  include Kinded
  include Graphed::Relation
  audited

  validates :creator_id, presence: true
  validates :relatable_from, presence: true
  validates :relationship_type, uniqueness: {
    scope: [:relatable_from_id, :relatable_to_id],
    case_sensitive: false,
    conditions: -> { where(is_deleted: false) }
  }, unless: :is_deleted
  validates :relatable_to, presence: true

  belongs_to :creator, class_name: "User"
  belongs_to :relatable_from, polymorphic: true
  belongs_to :relatable_to, polymorphic: true

  def graph_from_model
    relatable_from
  end

  def graph_to_model
    relatable_to
  end

  def set_relationship_type
    self.relationship_type = graph_model_type
    true
  end
end
