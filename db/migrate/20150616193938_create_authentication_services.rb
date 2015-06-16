class CreateAuthenticationServices < ActiveRecord::Migration
  def change
    create_table :authentication_services do |t|
      t.string :uuid
      t.string :base_uri
      t.string :name

      t.timestamps null: false
    end
  end
end
