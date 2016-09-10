require 'test_helper'

class PrivateKeyStoreTest < ActiveSupport::TestCase
  # Note we should probably stub the implementation of OpenSSL key generation
  test 'if_keysize_smaller_than_2048_is_invalid' do
    exception = assert_raises RuntimeError do
      PrivateKeyStore.new(1024).retrieve
    end
    assert_equal 'Invalid key size: 1024. Required size is between 2048 - 4096 bits', exception.message
  end

  test 'if_keysize_greater_than_4096_is_invalid' do
    exception = assert_raises RuntimeError do
      PrivateKeyStore.new(8192).retrieve
    end
    assert_equal 'Invalid key size: 8192. Required size is between 2048 - 4096 bits', exception.message
  end

  test 'if_keysize_equal_4096_is_valid' do
    assert_nothing_raised do
      PrivateKeyStore.new(4096).retrieve
    end
  end

  test 'if_keysize_equal_2048_is_valid' do
    assert_nothing_raised do
      PrivateKeyStore.new(2048).retrieve
    end
  end
end
