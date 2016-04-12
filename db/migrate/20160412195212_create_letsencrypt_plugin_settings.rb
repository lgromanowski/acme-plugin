class CreateLetsencryptPluginSettings < ActiveRecord::Migration
  def change
    create_table :letsencrypt_plugin_settings do |t|
      t.text :private_key

      t.timestamps null: false
    end
  end
end
