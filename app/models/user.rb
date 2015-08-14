require 'jwt'

class User < ActiveRecord::Base
  include StringIdCreator

  before_create :create_string_id
  self.primary_key = 'id'
  has_many :user_authentication_services
  accepts_nested_attributes_for :user_authentication_services

  has_many :projects, foreign_key: "creator_id"
  validates_each :auth_role_ids do |record, attr, value|
    record.errors.add(attr, 'does not exist') if value &&
      !value.empty? &&
      value.count > AuthRole.where(text_id: value).count
  end

  def auth_roles
    (auth_role_ids || []).collect do |role_id|
      AuthRole.where(text_id: role_id).first
    end
  end

  def auth_roles=(new_auth_role_ids)
    self.auth_role_ids = new_auth_role_ids
  end
end
