class CreateIdentityProviders < ActiveRecord::Migration[4.2]
  def change
    create_table :identity_providers do |t|
      t.string :host
      t.string :port
      t.string :type
      t.string :ldap_base

      t.timestamps null: false
    end
  end
end
