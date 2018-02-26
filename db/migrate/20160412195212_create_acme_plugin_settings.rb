class CreateAcmePluginSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :acme_plugin_settings do |t|
      t.text :private_key

      t.timestamps null: false
    end
  end
end
