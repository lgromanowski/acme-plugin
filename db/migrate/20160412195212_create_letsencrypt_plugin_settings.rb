class CreateLetsencryptPluginSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :letsencrypt_plugin_settings do |t|
      t.text :private_key

      t.timestamps null: false
    end
  end
end
