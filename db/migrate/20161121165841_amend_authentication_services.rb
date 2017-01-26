class AmendAuthenticationServices < ActiveRecord::Migration
  def change
    add_column :authentication_services, :login_initiation_uri, :string
    add_column :authentication_services, :login_response_type, :string
    add_column :authentication_services, :is_deprecated, :boolean, null: false, default: false
  end
end
