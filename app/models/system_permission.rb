class SystemPermission < ApplicationRecord
  default_scope { order('created_at DESC') }
  belongs_to :user
  belongs_to :auth_role

  validates :user_id, presence: true, uniqueness: true
  validates :auth_role_id, presence: true
  validates_each :auth_role do |record, attr, value|
    record.errors.add(attr, 'wrong context') if value &&
      !value.contexts.include?('system')
  end
end
