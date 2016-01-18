require 'test_helper'

class LetsencryptPluginTest < ActiveSupport::TestCase
  include Mocha::Integration::MiniTest

  test 'truth' do
    assert_kind_of Module, LetsencryptPlugin
  end

  test 'if_fail_when_private_key_is_nil' do
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new(private_key: nil)
      cg.create_client
    end
    assert_equal 'Private key is not set, please check your config/letsencrypt_plugin.yml file!', exception.message
  end

  test 'if_fail_when_private_key_is_empty' do
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new(private_key: '')
      cg.create_client
    end
    assert_equal 'Private key is not set, please check your config/letsencrypt_plugin.yml file!', exception.message
  end

  test 'if_fail_when_private_key_is_directory' do
    options = { private_key: 'public' }
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new(options)
      cg.create_client
    end
    assert_equal "Can not open private key: #{File.join(Rails.root, options[:private_key])}", exception.message
  end

  test 'if_keysize_smaller_than_2048_is_invalid' do
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new(private_key: 'key/test_keyfile_1024.pem')
      cg.create_client
    end
    assert_equal 'Invalid key size: 1024. Required size is between 2048 - 4096 bits', exception.message
  end

  test 'if_keysize_greater_than_4096_is_invalid' do
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new(private_key: 'key/test_keyfile_8192.pem')
      cg.create_client
    end
    assert_equal 'Invalid key size: 8192. Required size is between 2048 - 4096 bits', exception.message
  end

  test 'if_keysize_equal_4096_is_valid' do
    assert_nothing_raised do
      cg = LetsencryptPlugin::CertGenerator.new(private_key: 'key/test_keyfile_4096.pem')
      assert !cg.nil?
      cg.create_client
    end
  end

  test 'if_keysize_equal_2048_is_valid' do
    assert_nothing_raised do
      cg = LetsencryptPlugin::CertGenerator.new(private_key: 'key/test_keyfile_2048.pem')
      assert !cg.nil?
      cg.create_client
    end
  end

  # test 'register' do
  #   VCR.use_cassette('registration_agree_terms') do
  #     cg = LetsencryptPlugin::CertGenerator.new(private_key: 'key/test_keyfile_4096.pem',
  #       endpoint: 'https://acme-staging.api.letsencrypt.org',
  #       domain: 'example.com',
  #       email: 'foobarbaz@example.com')
  #     acme_client_mock = Acme::Client.new(private_key: cg.load_private_key, endpoint: cg.options[:endpoint])
  #     acme_client_auth_mock = Acme::Client::Resources::Authorization.new
  #     acme_client_auth_mock.stubs(:http01).returns(Acme::Client::Resources::Challenges::HTTP01)
  #     acme_client_cer_mock = Acme::Client::CertificateRequest.new
  #     acme_client_mock.stubs(:register).returns(Acme::Client::Resources::Registration)
  #     acme_client_mock.stubs(:new_certificate).with(acme_client_cer_mock).returns(nil)
  #     acme_client_mock.stubs(:authorize).returns(acme_client_auth_mock)
  #     cg.client = acme_client_mock
  #     assert !cg.nil?
  #     cg.generate_certificate
  #   end
  # end
end
