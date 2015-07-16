class Membership < ActiveRecord::Base
  include StringIdCreator

  before_create :create_string_id
  self.primary_key = 'id'
  belongs_to :user
  belongs_to :project

  validates :user_id, presence: true
  validates :project_id, presence: true
end
