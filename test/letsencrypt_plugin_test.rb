require 'test_helper'

class LetsencryptPluginTest < ActiveSupport::TestCase
  def setup
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  def teardown
    WebMock.allow_net_connect!
  end

  test 'truth' do
    assert_kind_of Module, LetsencryptPlugin
  end

  test 'if_fail_when_private_key_is_nil' do
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new(private_key: nil)
      cg.client
    end
    assert_equal 'Private key is not set, please check your config/letsencrypt_plugin.yml file!', exception.message
  end

  test 'if_fail_when_private_key_is_empty' do
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new(private_key: '')
      cg.client
    end
    assert_equal 'Private key is not set, please check your config/letsencrypt_plugin.yml file!', exception.message
  end

  test 'if_fail_when_private_key_is_directory' do
    options = { private_key: 'public' }
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new(options)
      cg.client
    end
    assert_equal "Can not open private key: #{File.join(Rails.root, options[:private_key])}", exception.message
  end

  test 'if_keysize_smaller_than_2048_is_invalid' do
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new(private_key: 'key/test_keyfile_1024.pem')
      cg.client
    end
    assert_equal 'Invalid key size: 1024. Required size is between 2048 - 4096 bits', exception.message
  end

  test 'if_keysize_greater_than_4096_is_invalid' do
    exception = assert_raises RuntimeError do
      cg = LetsencryptPlugin::CertGenerator.new(private_key: 'key/test_keyfile_8192.pem')
      cg.client
    end
    assert_equal 'Invalid key size: 8192. Required size is between 2048 - 4096 bits', exception.message
  end

  test 'if_keysize_equal_4096_is_valid' do
    assert_nothing_raised do
      cg = LetsencryptPlugin::CertGenerator.new(private_key: 'key/test_keyfile_4096.pem')
      assert !cg.nil?
      cg.client
    end
  end

  test 'if_keysize_equal_2048_is_valid' do
    assert_nothing_raised do
      cg = LetsencryptPlugin::CertGenerator.new(private_key: 'key/test_keyfile_2048.pem')
      assert !cg.nil?
      cg.client
    end
  end

  test 'register' do
    cg = LetsencryptPlugin::CertGenerator.new(private_key: 'key/test_keyfile_4096.pem',
                                              endpoint: 'https://acme-staging.api.letsencrypt.org',
                                              domain: 'example.com',
                                              email: 'foobarbaz@example.com')

    assert !cg.nil?

    stub_request(:head, 'https://acme-staging.api.letsencrypt.org/acme/new-reg')
      .with(headers: { 'Accept' => '*/*' })
      .to_return(status: 200, body: '', headers: {})

    stub_request(:post, 'https://acme-staging.api.letsencrypt.org/acme/new-reg')
      .with(body: '{"protected":"eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIiwibm9uY2UiOm51bGwsImp3ayI6eyJrdH'\
                  'kiOiJSU0EiLCJlIjoiQVFBQiIsIm4iOiJxN0gtQ2txRHZ3ekx2OWRBZ05rSmQzM2FiVEpFa0ZHSjhXbG'\
                  'IxRnZ1Y1F6MEFYWXJwWUx5ajdOYUNyQm90V1NaR2pFSnRQZ1k1M0xWWU1ET1BiOTktLTZEazNXVGhkT2'\
                  '03U01JTlZYWlZ1YmhhNmtoY1pFWFA1NEdic0NzcFBmNm5OcUJCeEhDblV3V01GOElRcWkwTVdSNHFOeG'\
                  '1LZEVrcE56dGFCd0xLU0ZWUHNRMHRGeXJHellhOEw0TkJqZWUyaWlEdWM2bHlMTkp6MnhfUUZMQWZneG'\
                  'w1cXdFa05FVGxNNzJNQlRsTTNrR1k4UjN2RkVNVEhQSUtCM3VQcHdScE1qOEw2M1JLenpmcmM5Q0Y2TD'\
                  'RNaG01b05GUENndmJDRWF6T0ctTEpwM2Q4bVlTZjBERE5RNlhoX0NnTG5TbXAzVWVmckpiQVFUZDBpSk'\
                  '4xa21TaV9fQmxOR1JDS1dFZDgyZzA2aHgwbVRhOXVZZEQxMFNXaVF5UHZIbDRzWER3M0JMN0VpOVlPNH'\
                  'poOUh6ZkpzUVhxY2hzQnZVZ2dEVG9IZVJwMnhmS0hEcmFFZ2JPX0FxaEMxRkdkTUtPUnJMWnBMQm1oam'\
                  'w0MFVvMWNLUXZsblZJZFJaQjU4QnoyZUhzNDVKN0ROYktsQm12cWZPQnJFN09nOHdEbFUzWFpIZ3dRZk'\
                  't4TUhBV29Qc0d2RG1KRjRZdFRmZ0R4NmZWS2VNbng5cXpJQ0plRlZmYnkzaUc4dE9XUFNKWFZUcXZ2Ql'\
                  'hiQnppT0h4bV9sOHpma3UwUmk3RXYwWUU2VEJGWDZiNDRES0FpVW9adkUwTm9taXhhYll2ZDAwWFFPNn'\
                  'dOMF9pdkN6Tmc0VVltaDlZUzJyM1E3YmloNFkyS3MyWllxdnNkazFnLWZiNGZRcyIsImtpZCI6IlFwSG'\
                  'dDOWxCZ0ZEX1A0dV9aejBNd2x0V1dUN1g2QlRZZnVPNUlob1VrUDAifX0",'\
                  '"payload":"eyJyZXNvdXJjZSI6Im5ldy1yZWciLCJjb250YWN0IjpbIm1haWx0bzpmb29iYXJiYXpAZ'\
                  'XhhbXBsZS5jb20iXX0",'\
                  '"signature":"T4aKq85rcACJdyEEx_Dw90lLypyPba6GSyG1YlFjCMwM7qdRlCsb3YIJE_Eia-A9IV'\
                  'lcXKc2rzvVOPvGB2bYmPCxep5o7uy1mkC7hKJhSEw97mT_sidrLamEKIrYtnVrW0KSO3EKEY-rUSMIeO'\
                  'AqLuZosSXLCEDlQTLqPUJPrhm8pDBRLzEqUO1HIMLfOEH5bWwXHofxL_QqUQjzMqIh_VWqy08MxuWETh'\
                  'DUyKPewBx1E_Y0H-vsM_D39SJA04s9fnIGyOlXISL1LZ9pFZ_W5rF25_P9vwks9m7E8iZFo-rFc073Ds'\
                  'Mzc_-5VbUgAoAqDZA69q8FTkgUkA6pu-vZsxeIb6OUNS6wxt6U4dqYS1aBXnhLeKvbIb7NqFmY8erzvc'\
                  'GXBvab1F0ndg6sw5PmrDZyOzcCKdA9eQk6LqCnfh8TcoywmJiqm2Ck49BUUe4t98AjvMNhaHel4Vn4HU'\
                  'XGX5xOEmt7gtsIE6YJP04ZoRKeWCrbYwjYIfLNlsbXpZj5oXPzBxOvwBuS6KL2HweeUGObiBsxRLsc1B'\
                  'oA_Na8Y2HtkWeZyUQPY1G3eSTPbBKR94T20LhcDSdNInzIFIhE5qI-WWCgHws6jB1K4Iip58zMgeTjGs'\
                  'D5Rc8ttBJwfprac8hBqMST_rzo-gn70b-iT3PJkasUbm32UwOxXtavJ5g"}',
            headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                       'User-Agent' => 'Faraday v0.9.2' })
      .to_return(status: 200, body: '', headers: {})

    assert_nothing_raised do
      cg.register
    end
  end

  test 'register_with_privkey_in_db' do
    cg = LetsencryptPlugin::CertGenerator.new(private_key_in_db: true,
                                              endpoint: 'https://acme-staging.api.letsencrypt.org',
                                              domain: 'example.com',
                                              email: 'foobarbaz@example.com')

    assert !cg.nil?

    stub_request(:head, 'https://acme-staging.api.letsencrypt.org/acme/new-reg')
      .with(headers: { 'Accept' => '*/*' })
      .to_return(status: 200, body: '', headers: {})

    stub_request(:post, 'https://acme-staging.api.letsencrypt.org/acme/new-reg')
      .with(body: '{"protected":"eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIiwibm9uY2UiOm51bGwsImp3ayI6eyJrdH'\
                  'kiOiJSU0EiLCJlIjoiQVFBQiIsIm4iOiJxN0gtQ2txRHZ3ekx2OWRBZ05rSmQzM2FiVEpFa0ZHSjhXbG'\
                  'IxRnZ1Y1F6MEFYWXJwWUx5ajdOYUNyQm90V1NaR2pFSnRQZ1k1M0xWWU1ET1BiOTktLTZEazNXVGhkT2'\
                  '03U01JTlZYWlZ1YmhhNmtoY1pFWFA1NEdic0NzcFBmNm5OcUJCeEhDblV3V01GOElRcWkwTVdSNHFOeG'\
                  '1LZEVrcE56dGFCd0xLU0ZWUHNRMHRGeXJHellhOEw0TkJqZWUyaWlEdWM2bHlMTkp6MnhfUUZMQWZneG'\
                  'w1cXdFa05FVGxNNzJNQlRsTTNrR1k4UjN2RkVNVEhQSUtCM3VQcHdScE1qOEw2M1JLenpmcmM5Q0Y2TD'\
                  'RNaG01b05GUENndmJDRWF6T0ctTEpwM2Q4bVlTZjBERE5RNlhoX0NnTG5TbXAzVWVmckpiQVFUZDBpSk'\
                  '4xa21TaV9fQmxOR1JDS1dFZDgyZzA2aHgwbVRhOXVZZEQxMFNXaVF5UHZIbDRzWER3M0JMN0VpOVlPNH'\
                  'poOUh6ZkpzUVhxY2hzQnZVZ2dEVG9IZVJwMnhmS0hEcmFFZ2JPX0FxaEMxRkdkTUtPUnJMWnBMQm1oam'\
                  'w0MFVvMWNLUXZsblZJZFJaQjU4QnoyZUhzNDVKN0ROYktsQm12cWZPQnJFN09nOHdEbFUzWFpIZ3dRZk'\
                  't4TUhBV29Qc0d2RG1KRjRZdFRmZ0R4NmZWS2VNbng5cXpJQ0plRlZmYnkzaUc4dE9XUFNKWFZUcXZ2Ql'\
                  'hiQnppT0h4bV9sOHpma3UwUmk3RXYwWUU2VEJGWDZiNDRES0FpVW9adkUwTm9taXhhYll2ZDAwWFFPNn'\
                  'dOMF9pdkN6Tmc0VVltaDlZUzJyM1E3YmloNFkyS3MyWllxdnNkazFnLWZiNGZRcyIsImtpZCI6IlFwSG'\
                  'dDOWxCZ0ZEX1A0dV9aejBNd2x0V1dUN1g2QlRZZnVPNUlob1VrUDAifX0",'\
                  '"payload":"eyJyZXNvdXJjZSI6Im5ldy1yZWciLCJjb250YWN0IjpbIm1haWx0bzpmb29iYXJiYXpAZ'\
                  'XhhbXBsZS5jb20iXX0",'\
                  '"signature":"T4aKq85rcACJdyEEx_Dw90lLypyPba6GSyG1YlFjCMwM7qdRlCsb3YIJE_Eia-A9IVl'\
                  'cXKc2rzvVOPvGB2bYmPCxep5o7uy1mkC7hKJhSEw97mT_sidrLamEKIrYtnVrW0KSO3EKEY-rUSMIeOA'\
                  'qLuZosSXLCEDlQTLqPUJPrhm8pDBRLzEqUO1HIMLfOEH5bWwXHofxL_QqUQjzMqIh_VWqy08MxuWEThD'\
                  'UyKPewBx1E_Y0H-vsM_D39SJA04s9fnIGyOlXISL1LZ9pFZ_W5rF25_P9vwks9m7E8iZFo-rFc073DsM'\
                  'zc_-5VbUgAoAqDZA69q8FTkgUkA6pu-vZsxeIb6OUNS6wxt6U4dqYS1aBXnhLeKvbIb7NqFmY8erzvcG'\
                  'XBvab1F0ndg6sw5PmrDZyOzcCKdA9eQk6LqCnfh8TcoywmJiqm2Ck49BUUe4t98AjvMNhaHel4Vn4HUX'\
                  'GX5xOEmt7gtsIE6YJP04ZoRKeWCrbYwjYIfLNlsbXpZj5oXPzBxOvwBuS6KL2HweeUGObiBsxRLsc1Bo'\
                  'A_Na8Y2HtkWeZyUQPY1G3eSTPbBKR94T20LhcDSdNInzIFIhE5qI-WWCgHws6jB1K4Iip58zMgeTjGsD'\
                  '5Rc8ttBJwfprac8hBqMST_rzo-gn70b-iT3PJkasUbm32UwOxXtavJ5g"}',
            headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                       'User-Agent' => 'Faraday v0.9.2' })
      .to_return(status: 200, body: '', headers: {})

    assert_nothing_raised do
      cg.register
    end
  end

  test 'register_and_authorize' do
    cg = LetsencryptPlugin::CertGenerator.new(private_key: 'key/test_keyfile_4096.pem',
                                              endpoint: 'https://acme-staging.api.letsencrypt.org',
                                              domain: 'example.com',
                                              email: 'foobarbaz@example.com')

    assert !cg.nil?

    stub_request(:head, 'https://acme-staging.api.letsencrypt.org/acme/new-reg')
      .with(headers: { 'Accept' => '*/*' })
      .to_return(status: 200, body: '', headers: {})

    protected_field = '"protected":"eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIiwibm9uY2UiOm51bGwsImp3ayI6eyJ'\
                      'rdHkiOiJSU0EiLCJlIjoiQVFBQiIsIm4iOiJxN0gtQ2txRHZ3ekx2OWRBZ05rSmQzM2FiVEpFa0Z'\
                      'HSjhXbGIxRnZ1Y1F6MEFYWXJwWUx5ajdOYUNyQm90V1NaR2pFSnRQZ1k1M0xWWU1ET1BiOTktLTZ'\
                      'EazNXVGhkT203U01JTlZYWlZ1YmhhNmtoY1pFWFA1NEdic0NzcFBmNm5OcUJCeEhDblV3V01GOEl'\
                      'RcWkwTVdSNHFOeG1LZEVrcE56dGFCd0xLU0ZWUHNRMHRGeXJHellhOEw0TkJqZWUyaWlEdWM2bHl'\
                      'MTkp6MnhfUUZMQWZneGw1cXdFa05FVGxNNzJNQlRsTTNrR1k4UjN2RkVNVEhQSUtCM3VQcHdScE1'\
                      'qOEw2M1JLenpmcmM5Q0Y2TDRNaG01b05GUENndmJDRWF6T0ctTEpwM2Q4bVlTZjBERE5RNlhoX0N'\
                      'nTG5TbXAzVWVmckpiQVFUZDBpSk4xa21TaV9fQmxOR1JDS1dFZDgyZzA2aHgwbVRhOXVZZEQxMFN'\
                      'XaVF5UHZIbDRzWER3M0JMN0VpOVlPNHpoOUh6ZkpzUVhxY2hzQnZVZ2dEVG9IZVJwMnhmS0hEcmF'\
                      'FZ2JPX0FxaEMxRkdkTUtPUnJMWnBMQm1oamw0MFVvMWNLUXZsblZJZFJaQjU4QnoyZUhzNDVKN0R'\
                      'OYktsQm12cWZPQnJFN09nOHdEbFUzWFpIZ3dRZkt4TUhBV29Qc0d2RG1KRjRZdFRmZ0R4NmZWS2V'\
                      'Nbng5cXpJQ0plRlZmYnkzaUc4dE9XUFNKWFZUcXZ2QlhiQnppT0h4bV9sOHpma3UwUmk3RXYwWUU'\
                      '2VEJGWDZiNDRES0FpVW9adkUwTm9taXhhYll2ZDAwWFFPNndOMF9pdkN6Tmc0VVltaDlZUzJyM1E'\
                      '3YmloNFkyS3MyWllxdnNkazFnLWZiNGZRcyIsImtpZCI6IlFwSGdDOWxCZ0ZEX1A0dV9aejBNd2x'\
                      '0V1dUN1g2QlRZZnVPNUlob1VrUDAifX0"'

    stub_request(:post, 'https://acme-staging.api.letsencrypt.org/acme/new-reg')
      .with(body: "{#{protected_field},"\
                  '"payload":"eyJyZXNvdXJjZSI6Im5ldy1yZWciLCJjb250YWN0IjpbIm1haWx0bzpmb29iYXJiYXpAZ'\
                  'XhhbXBsZS5jb20iXX0",'\
                  '"signature":"T4aKq85rcACJdyEEx_Dw90lLypyPba6GSyG1YlFjCMwM7qdRlCsb3YIJE_Eia-A9IVl'\
                  'cXKc2rzvVOPvGB2bYmPCxep5o7uy1mkC7hKJhSEw97mT_sidrLamEKIrYtnVrW0KSO3EKEY-rUSMIeOA'\
                  'qLuZosSXLCEDlQTLqPUJPrhm8pDBRLzEqUO1HIMLfOEH5bWwXHofxL_QqUQjzMqIh_VWqy08MxuWEThD'\
                  'UyKPewBx1E_Y0H-vsM_D39SJA04s9fnIGyOlXISL1LZ9pFZ_W5rF25_P9vwks9m7E8iZFo-rFc073DsM'\
                  'zc_-5VbUgAoAqDZA69q8FTkgUkA6pu-vZsxeIb6OUNS6wxt6U4dqYS1aBXnhLeKvbIb7NqFmY8erzvcG'\
                  'XBvab1F0ndg6sw5PmrDZyOzcCKdA9eQk6LqCnfh8TcoywmJiqm2Ck49BUUe4t98AjvMNhaHel4Vn4HUX'\
                  'GX5xOEmt7gtsIE6YJP04ZoRKeWCrbYwjYIfLNlsbXpZj5oXPzBxOvwBuS6KL2HweeUGObiBsxRLsc1Bo'\
                  'A_Na8Y2HtkWeZyUQPY1G3eSTPbBKR94T20LhcDSdNInzIFIhE5qI-WWCgHws6jB1K4Iip58zMgeTjGsD'\
                  '5Rc8ttBJwfprac8hBqMST_rzo-gn70b-iT3PJkasUbm32UwOxXtavJ5g"}',
            headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                       'User-Agent' => 'Faraday v0.9.2' })
      .to_return(status: 200, body: '', headers: {})

    stub_request(:post, 'https://acme-staging.api.letsencrypt.org/acme/new-authz')
      .with(body: "{#{protected_field},"\
                  '"payload":"eyJyZXNvdXJjZSI6Im5ldy1hdXRoeiIsImlkZW50aWZpZXIiOnsidHlwZSI6ImRucyIsI'\
                  'nZhbHVlIjoiZXhhbXBsZS5jb20ifX0",'\
                  '"signature":"Rz1azArX57oCwc4fw9K12zNoMk5v0w7A22NyKrPQ9p2V7KOvUeAQyc4QJ7joGB0D5J1'\
                  'RNiz1_hQEsCiY8mSOqUAJiUIMEJLrPiFEBtIaDPh3ho9LxBdrfm2Dy-iszMD08tTu5xU7fxuPamJAloh'\
                  '08vVNBDG17TSpSjNH69u8_lzwNGwVB4NlV_-L5PynDebDtXLGYP9EuUzVEB4PzJTyLD0p5wT7CGopDtr'\
                  '4zX8a4sOhKIILLJwNNa3AiAW01SE6hPMAmCDn-drVDt5jtxDUaNwEQMSWtzEj5EbKK10dGFB7mIHFmky'\
                  'VCuNn_qx8pG1HYGKwbq61itrwLhXclNmDeCtJMiWGUQPnfNCsmmvI_b9VNCEnc7f7iXnQZpUhIamM3Gz'\
                  'JAePDMbjVku08-49cosOfU5k5xSs8b2xubxMivnGwXVmkUCfQe3uuqDE_zTsgvh8o6f3akeP22bwFWBy'\
                  'ihaTim1cXNEuMWEPfWBiScI41hE577K4MUNRhH9-Bp9cFzzUbvJA0q1ao_JSeNyuJyi0DOBjJb7aV3TI'\
                  'xaf8Q8S1D-X3PT7AGwDYJudpDDC60Go6qUlu-3B4eY9hLXzqPc7CUK1kO_NrIVsu3xL-IlRiqhw-IFgT'\
                  'NCUc03c6G-5lB24itAHufVZ3pww50viSs9Sj-9D5Nu5e_x9lqv8U6VdU"}',
            headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                       'User-Agent' => 'Faraday v0.9.2' })
      .to_return(status: 200,
                 body: '{'\
                       ' "status": "valid",'\
                       ' "expires": "2020-12-31T23:59:59+01:00",'\
                       ' "identifier":'\
                       ' {'\
                       '   "type": "dns", "value": "example.org"'\
                       ' },'\
                       ' "challenges":'\
                       ' ['\
                       ' {'\
                       ' "type": "http-01",'\
                       ' "status": "pending",'\
                       ' "uri": "https://acme-staging.api.letsencrypt.org/acme/challenge/JmusiS7mAL_OZ1tIbwQxpYadpM9E3Azbywa6KSveuEk/93",'\
                       ' "token":"-Jbrff2stnTiZXFFKJHXtYrZof2dqlQaegRbeG1t6BY"'\
                       ' }'\
                       ' ],'\
                       ' "combinations":[[0]]'\
                       '}',
                 headers: { 'Content-Type' => 'application/json',
                            'Link' => '<https://acme-staging.api.letsencrypt.org/acme/new-cert>;rel="next"',
                            'Location' => 'https://acme-staging.api.letsencrypt.org/acme/authz/JmusiS7mAL_OZ1tIbwQxpYadpM9E3Azbywa6KSveuEk',
                            'Replay-Nonce' => 'Hdhg8ovViG7ipkQrQRW2dsDbK5vxhGd_4T9HDqg3u4c' })

    assert_nothing_raised do
      cg.register
      cg.authorize
    end
  end
end
