class CreateAuthenticationServices < ActiveRecord::Migration[4.2]
  def change
    create_table :authentication_services, id: :uuid do |t|
      t.uuid :service_id
      t.string :base_uri
      t.string :name

      t.timestamps null: false
    end
  end
end
