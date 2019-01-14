class Activity < ApplicationRecord
  include Kinded
  include Graphed::Node

  include SearchableModel
  # change this variable to a new uuid (lowercase letters!)
  # any time the mappings below change
  def self.mapping_version
    'bab2183a-5ed5-4cd3-b05e-916e20817dd7'
  end

  # change this to a new uuid (lowercase letters!) any time
  #  - a migration is created to add/remove fields
  #    and its serializers (standard and search)
  #  - relationships are added to/removed from the serializers
  def self.migration_version
    '429d08e4-622d-456a-a87d-84c288857320'
  end

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
