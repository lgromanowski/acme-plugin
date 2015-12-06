class CreateLetsencryptPluginChallenges < ActiveRecord::Migration
  def change
    create_table :letsencrypt_plugin_challenges do |t|
      t.text :response

      t.timestamps null: false
    end
  end
end
