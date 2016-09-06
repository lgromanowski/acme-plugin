module LetsencryptPlugin

  Config = Class.new(OpenStruct) 

  # This is a class whose responcsibility is to load the lets_encrypt configuration file
  module Configuration
    
    def self.load_file(filename = Rails.root.join('config', 'letsencrypt_plugin.yml'))
      config_data = parse_yaml_file(filename)
      create_config(config_data)
    end

    private

    def self.create_config(config_hash)
      Config.new(config_hash.merge(config_hash.fetch(Rails.env, {})) || {})         
    end

    def self.read_file(filename)
      File.read(filename)
    end

    def self.evaluate_file(filename)
      ERB.new(read_file(filename)).result
    end

    def self.parse_yaml_file(filename)
      YAML.load(evaluate_file(filename))
    end

  end
  
end
