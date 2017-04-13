class CreateMetaTemplates < ActiveRecord::Migration[4.2]
  def change
    create_table :meta_templates do |t|
      t.uuid :templatable_id
      t.string :templatable_type
      t.uuid :template_id

      t.timestamps null: false
    end
  end
end
