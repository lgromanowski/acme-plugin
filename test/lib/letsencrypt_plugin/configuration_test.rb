require 'test_helper'

class LetsencryptPlugin::ConfigurationTest < ActiveSupport::TestCase
  
  test 'reads multiple domains from test config' do
    config_file_path = Rails.root.join('config', 'letsencrypt_plugin.yml')
    config = LetsencryptPlugin::Configuration.load_file(config_file_path)
    domains = config.domain.split(' ')
    assert_kind_of Array, domains
    assert_operator domains.length, :>, 0
  end

end
