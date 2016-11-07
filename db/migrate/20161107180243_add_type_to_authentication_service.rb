class AddTypeToAuthenticationService < ActiveRecord::Migration
  def change
    add_column :authentication_services, :type, :string
  end
end
