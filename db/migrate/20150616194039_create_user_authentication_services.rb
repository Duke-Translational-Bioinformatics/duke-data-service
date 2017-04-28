class CreateUserAuthenticationServices < ActiveRecord::Migration[4.2]
  def change
    create_table :user_authentication_services, id: :uuid do |t|
      t.uuid :user_id
      t.uuid :authentication_service_id
      t.string :uid

      t.timestamps null: false
    end
  end
end
