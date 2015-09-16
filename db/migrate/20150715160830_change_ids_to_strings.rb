class ChangeIdsToStrings < ActiveRecord::Migration
  def change
    change_column :users, :id, :string
    remove_column :users, :uuid, :string
    change_column :user_authentication_services, :user_id, :string
    change_column :projects, :id, :string
    change_column :projects, :creator_id, :string
    remove_column :projects, :uuid, :string
    change_column :memberships, :id, :string
    change_column :memberships, :project_id, :string
    change_column :memberships, :user_id, :string
  end
end
