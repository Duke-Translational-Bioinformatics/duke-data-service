class CreateAuthenticationServices < ActiveRecord::Migration
  def change
    create_table :authentication_services, id: :uuid do |t|
      t.string :base_uri
      t.string :name

      t.timestamps null: false
    end
  end
end
