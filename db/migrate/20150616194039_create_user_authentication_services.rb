class CreateUserAuthenticationServices < ActiveRecord::Migration
  def change
    create_table :user_authentication_services do |t|
      t.integer :user_id
      t.integer :authentication_service_id
      t.string :uid

      t.timestamps null: false
    end
  end
end
