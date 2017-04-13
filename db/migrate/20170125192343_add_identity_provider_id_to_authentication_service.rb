class AddIdentityProviderIdToAuthenticationService < ActiveRecord::Migration[4.2]
  def change
    add_column :authentication_services, :identity_provider_id, :integer
  end
end
