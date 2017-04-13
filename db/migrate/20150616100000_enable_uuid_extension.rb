class EnableUuidExtension < ActiveRecord::Migration[4.2]
  def change
    enable_extension 'uuid-ossp'
  end
end
