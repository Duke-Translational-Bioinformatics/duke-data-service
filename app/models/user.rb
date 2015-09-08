require 'jwt'

class User < ActiveRecord::Base

  has_many :user_authentication_services
  accepts_nested_attributes_for :user_authentication_services

  has_many :projects, foreign_key: "creator_id"
  has_many :data_files, foreign_key: "creator_id"
  has_many :uploads, through: :data_files
  has_many :affiliations

  validates :username, presence: true, uniqueness: true
  validates_each :auth_role_ids do |record, attr, value|
    record.errors.add(attr, 'does not exist') if value &&
      !value.empty? &&
      value.count > AuthRole.where(id: value).count
  end

  def auth_roles
    (auth_role_ids || []).collect do |role_id|
      AuthRole.where(id: role_id).first
    end
  end

  def auth_roles=(new_auth_role_ids)
    self.auth_role_ids = new_auth_role_ids
  end

  def project_count
    self.projects.count
  end

  def file_count
    self.data_files.count
  end

  def storage_bytes
    self.uploads.sum(:size)
  end
end
