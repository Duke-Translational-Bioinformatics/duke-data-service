class RecreateMetaTemplates < ActiveRecord::Migration
  def change
    drop_table :meta_templates
    create_table :meta_templates, id: :uuid do |t|
      t.uuid :templatable_id
      t.string :templatable_type
      t.uuid :template_id

      t.timestamps null: false
    end
  end
end
