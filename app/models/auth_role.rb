class AuthRole < ApplicationRecord
  has_one :user, through: :system_permission

  self.primary_key = 'id'
  validates :id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :description, presence: true
  validates :permissions, presence: true
  validates :contexts, presence: true

  scope :with_context, ->(context) { where('contexts @> ?', [context].to_json) }
  scope :with_permission, ->(permission) { where('permissions @> ?', [permission].to_json) }

  def self.available_permissions(context=nil)
    context = context.to_sym if context
    contextual_permissions = {
      system: ['system_admin'],
      project: %w(
        view_project
        update_project
        delete_project
        manage_project_permissions
        download_file
        create_file
        update_file
        delete_file
      )
    }
    if context
      contextual_permissions[context]
    else
      contextual_permissions.values.flatten
    end
  end
end
