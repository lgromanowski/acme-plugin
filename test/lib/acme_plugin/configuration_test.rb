require 'test_helper'

module AcmePlugin
  class ConfigurationTest < ActiveSupport::TestCase
    test 'reads multiple domains from test config' do
      config_file_path = Rails.root.join('config', 'acme_plugin.yml')
      config = AcmePlugin::Configuration.load_file(config_file_path)
      domains = config.domain.split(' ')
      assert_kind_of Array, domains
      assert_operator domains.length, :>, 0
    end
  end
end
