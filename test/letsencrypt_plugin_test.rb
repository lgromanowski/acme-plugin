require 'test_helper'

class LetsencryptPluginTest < ActiveSupport::TestCase
  setup do
    Dummy::Application.load_tasks
  end

  test 'truth' do
    assert_kind_of Module, LetsencryptPlugin
  end

  test 'if_fail_when_private_key_is_nil' do
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new({ private_key: nil })
    end
    assert_equal 'Private key is not set, please check your config/letsencrypt_plugin.yml file!', exception.message
  end

  test 'if_fail_when_private_key_is_empty' do
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new({ private_key: '' })
    end
    assert_equal 'Private key is not set, please check your config/letsencrypt_plugin.yml file!', exception.message
  end

  test 'if_fail_when_private_key_is_directory' do
    options = { private_key: 'public' }
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new(options)
    end
    assert_equal "Can not open private key: #{File.join(Rails.root, options[:private_key])}", exception.message
  end

  test 'if_keysize_smaller_than_2048_is_invalid' do
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new({ private_key: 'key/test_keyfile_1024.pem' })
    end
    assert_equal 'Invalid key size: 1024. Required size is between 2048 - 4096 bits', exception.message
  end

  test 'if_keysize_greater_than_4096_is_invalid' do
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new({ private_key: 'key/test_keyfile_8192.pem' })
    end
    assert_equal 'Invalid key size: 8192. Required size is between 2048 - 4096 bits', exception.message
  end

  test 'if_keysize_equal_4096_is_valid' do
    cg = LetsencryptPlugin::CertGenerator.new({ private_key: 'key/test_keyfile_4096.pem' })
    assert cg != nil
  end

  test 'if_keysize_equal_2048_is_valid' do
    cg = LetsencryptPlugin::CertGenerator.new({ private_key: 'key/test_keyfile_2048.pem' })
    assert cg != nil
  end

end
