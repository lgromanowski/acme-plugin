config = YAML.load_file(Rails.root.join('config', 'letsencrypt_plugin.yml'))
config.merge! config.fetch(Rails.env, {})
LetsencryptPlugin.config = config
