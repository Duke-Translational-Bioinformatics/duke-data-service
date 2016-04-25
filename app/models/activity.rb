class Activity < ActiveRecord::Base
  include Kinded
  include Graphed
  after_create :graph_node
  after_save :logically_delete_graph_node
  after_destroy :delete_graph_node

  audited

  validates :name, presence: true
end
