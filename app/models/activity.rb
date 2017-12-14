class Activity < ActiveRecord::Base
  include Kinded
  include Graphed::Node
  include RequestAudited

  include SearchableModel
  # change this to a new uuid any time
  #  - a migration is created to add/remove fields
  #    and its serializers (standard and search)
  #  - relationships are added to/removed from the serializers
  @@migration_version = '429D08E4-622D-456A-A87D-84C288857320'

  # change this variable to a new uuid any time the mappings below change
  @@mapping_version = 'BAB2183A-5ED5-4CD3-B05E-916E20817DD7'

  def self.mapping_version
    @@mapping_version
  end

  def self.migration_version
    @@migration_version
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
