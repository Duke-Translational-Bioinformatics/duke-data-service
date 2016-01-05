class InstallAudited < ActiveRecord::Migration
  def self.up
    create_table :audits, :force => true do |t|
      t.column :auditable_id, :uuid
      t.column :auditable_type, :string
      t.column :associated_id, :uuid
      t.column :associated_type, :string
      t.column :user_id, :uuid
      t.column :user_type, :string
      t.column :username, :string
      t.column :action, :string
      t.column :audited_changes, :text
      t.column :version, :integer, :default => 0
      t.column :comment, :jsonb
      t.column :remote_address, :string
      t.column :request_uuid, :string
      t.column :created_at, :datetime
    end

    add_index :audits, [:auditable_id, :auditable_type], :name => 'auditable_index'
    add_index :audits, [:associated_id, :associated_type], :name => 'associated_index'
    add_index :audits, [:user_id, :user_type], :name => 'user_index'
    add_index :audits, :request_uuid
    add_index :audits, :created_at
    add_index  :audits, :comment, using: :gin
  end

  def self.down
    drop_table :audits
  end
end
