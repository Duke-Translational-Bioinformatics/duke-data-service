class SoftwareAgent < ActiveRecord::Base
  audited
  include Kinded
  include Graphed
  after_create :graph_node

  belongs_to :creator, class_name: "User"
  has_one :api_key

  validates :name, presence: true, unless: :is_deleted
  validates :creator_id, presence: true, unless: :is_deleted

  def graph_node
    super('Agent')
  end
end
