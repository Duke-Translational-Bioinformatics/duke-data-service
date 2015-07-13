class ProjectPermission < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  validates :user_id, presence: true
  validates :project_id, presence: true
  validates_each :auth_role_ids do |record, attr, value|
    record.errors.add(attr, 'does not exist') if value &&
      !value.empty? &&
      value.count > AuthRole.where(text_id: value).count
  end

  def auth_roles
    auth_role_ids.collect do |role_id|
      AuthRole.where(text_id: role_id).first
    end
  end

  def auth_roles=(new_auth_role_ids)
    self.auth_role_ids = new_auth_role_ids
  end
end
