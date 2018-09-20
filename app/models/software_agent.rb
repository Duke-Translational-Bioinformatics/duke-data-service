class SoftwareAgent < ActiveRecord::Base
  audited
  include Kinded
  include Graphed::Node

  belongs_to :creator, class_name: "User"
  has_one :api_key

  validates :name, presence: true, unless: :is_deleted
  validates :creator_id, presence: true, unless: :is_deleted

  def graph_model_name
    'Agent'
  end

  def kind
    super('software-agent')
  end
end
