CONFIG = YAML.load_file(Rails.root.join('config', 'letsencrypt_plugin.yml'))
CONFIG.merge! CONFIG.fetch(Rails.env, {})
CONFIG.symbolize_keys!