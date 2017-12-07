class Activity < ActiveRecord::Base
  include Kinded
  include Graphed::Node
  include RequestAudited
  include SearchableModel
  before_create :set_default_started_on
  after_save :logically_delete_graph_node

  audited

  belongs_to :creator, class_name: 'User'
  has_many :generated_by_activity_prov_relations, as: :relatable_to
  has_many :invalidated_by_activity_prov_relations, as: :relatable_to
  has_many :used_prov_relations, as: :relatable_from
  has_many :tags, as: :taggable
  has_many :meta_templates, as: :templatable

  validates :name, presence: true
  validates :creator_id, presence: true
  validate :valid_dates

  def valid_dates
    if  started_on && ended_on && started_on > ended_on
      self.errors.add :ended_on, ' must be >= started_on'
    end
  end

  def set_default_started_on
    self.started_on = DateTime.now unless self.started_on
  end
end
