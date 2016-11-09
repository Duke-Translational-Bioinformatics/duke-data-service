class AddTypeToAuthenticationService < ActiveRecord::Migration
  def change
    add_column :authentication_services, :type, :string
    add_column :authentication_services, :client_id, :string
    add_column :authentication_services, :client_secret, :string
    add_column :authentication_services, :is_default, :boolean, null: false, default: false
  end
end
