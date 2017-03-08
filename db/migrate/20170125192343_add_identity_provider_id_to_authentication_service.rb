class AddIdentityProviderIdToAuthenticationService < ActiveRecord::Migration
  def change
    add_column :authentication_services, :identity_provider_id, :integer
  end
end
