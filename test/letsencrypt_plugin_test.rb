require 'test_helper'

class LetsencryptPluginTest < ActiveSupport::TestCase
  ACME_VERSION = 'v0.4.1'.freeze
  ACME_USER_AGENT = "Acme::Client #{ACME_VERSION} (https://github.com/unixcharles/acme-client)".freeze
  ENDPOINT_URL = 'https://acme-staging.api.letsencrypt.org'.freeze
  API_URL = "#{ENDPOINT_URL}/acme".freeze

  def setup
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  def teardown
    WebMock.allow_net_connect!
  end

  test 'is_valid_module' do
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

  test 'register with text based private key' do
    cg = LetsencryptPlugin::CertGenerator.new(private_key: %(
-----BEGIN RSA PRIVATE KEY-----
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
-----END RSA PRIVATE KEY-----),
                                              endpoint: ENDPOINT_URL,
                                              domain: 'example.com',
                                              email: 'foobarbaz@example.com')
    assert !cg.nil?

    stub_request(:head, "#{API_URL}/new-reg")
      .with(headers: { 'Accept' => '*/*' })
      .to_return(status: 200, body: '', headers: {})

    stub_request(:post, "#{API_URL}/new-reg")
      .with(body: '{"protected":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp3ayI6eyJlIjoiQVFBQiIsImt0eS'\
        'I6IlJTQSIsIm4iOiJxN0gtQ2txRHZ3ekx2OWRBZ05rSmQzM2FiVEpFa0ZHSjhXbGIxRnZ1Y1F6MEFYWX'\
        'JwWUx5ajdOYUNyQm90V1NaR2pFSnRQZ1k1M0xWWU1ET1BiOTktLTZEazNXVGhkT203U01JTlZYWlZ1Ym'\
        'hhNmtoY1pFWFA1NEdic0NzcFBmNm5OcUJCeEhDblV3V01GOElRcWkwTVdSNHFOeG1LZEVrcE56dGFCd0'\
        'xLU0ZWUHNRMHRGeXJHellhOEw0TkJqZWUyaWlEdWM2bHlMTkp6MnhfUUZMQWZneGw1cXdFa05FVGxNNz'\
        'JNQlRsTTNrR1k4UjN2RkVNVEhQSUtCM3VQcHdScE1qOEw2M1JLenpmcmM5Q0Y2TDRNaG01b05GUENndm'\
        'JDRWF6T0ctTEpwM2Q4bVlTZjBERE5RNlhoX0NnTG5TbXAzVWVmckpiQVFUZDBpSk4xa21TaV9fQmxOR1'\
        'JDS1dFZDgyZzA2aHgwbVRhOXVZZEQxMFNXaVF5UHZIbDRzWER3M0JMN0VpOVlPNHpoOUh6ZkpzUVhxY2'\
        'hzQnZVZ2dEVG9IZVJwMnhmS0hEcmFFZ2JPX0FxaEMxRkdkTUtPUnJMWnBMQm1oamw0MFVvMWNLUXZsbl'\
        'ZJZFJaQjU4QnoyZUhzNDVKN0ROYktsQm12cWZPQnJFN09nOHdEbFUzWFpIZ3dRZkt4TUhBV29Qc0d2RG'\
        '1KRjRZdFRmZ0R4NmZWS2VNbng5cXpJQ0plRlZmYnkzaUc4dE9XUFNKWFZUcXZ2QlhiQnppT0h4bV9sOH'\
        'pma3UwUmk3RXYwWUU2VEJGWDZiNDRES0FpVW9adkUwTm9taXhhYll2ZDAwWFFPNndOMF9pdkN6Tmc0VV'\
        'ltaDlZUzJyM1E3YmloNFkyS3MyWllxdnNkazFnLWZiNGZRcyJ9LCJub25jZSI6bnVsbH0",'\
        '"payload":"eyJyZXNvdXJjZSI6Im5ldy1yZWciLCJjb250YWN0IjpbIm1haWx0bzpmb29iYXJiYXpAZ'\
        'XhhbXBsZS5jb20iXX0",'\
        '"signature":"aQ6T0XVo9jS_jXlvQ6bjAfqcrMYpQTPE9_CD7v1hDBUzKpSoygAJmrbb0kSumMkWf-r'\
        'acxG5i7tcD4ed32ap1OsWUoPGWhXkQifAqToYMdfBzjwaS_OfjPpFflPOZmUvOygtGt3LTsdhA27PCSC'\
        'saZDlozz2143b00QhZ-gVkFRJEwOMN22ByOsL-1_R_UEp7mqwQKzeZ_nsW7japvGWcru13bzqiD2b069'\
        'kwrfksnMIMSjFWnJPnxCLpY-DQn8kCBeJfljW-mOJyZFck1ko0KBiOEbY_k0IJ0aspwg9lGRLkVX-wWV'\
        '8Q_e8gwoLjmaXouUxAl2E3wNInXRJkgDOMfEUSOHzxI6WFYLzhVKVl7ktP7zx21my2vL_J_nROTDaVIU'\
        'qJgdUgEZ40KR_Kjd_pRKPcB8kHyKtDnCopmrPXLu0QCuHYAn_M-cYgkFOyvplJNodaZfKamLuwChywPl'\
        'DC5tr1BQvdlUVp-cwr_C_KU-Kpkws924xI0ah8ksuwsHpkp2458aVEIeDEEw7FgHZXUPKXaJcBIHjQ1R'\
        'vnm062Ub_4LR25TrKTgftDCftK2YtN4LA-jtlfOrdM47xZatAzhmFy_vFIIu_-phh5he0nn8Mx2byjsZ'\
        '1M-DeW0Wl9_zxhhOo1gtmFhtguCKw3W0mdcdDZmhRleNS-HtYA0w41LA"}',
            headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                       'User-Agent' => ACME_USER_AGENT })
      .to_return(status: 200, body: '', headers: {})

    assert_nothing_raised do
      cg.register
    end
  end

  test 'register' do
    cg = LetsencryptPlugin::CertGenerator.new(private_key: 'key/test_keyfile_4096.pem',
                                              endpoint: ENDPOINT_URL,
                                              domain: 'example.com',
                                              email: 'foobarbaz@example.com')
    assert !cg.nil?

    stub_request(:head, "#{API_URL}/new-reg")
      .with(headers: { 'Accept' => '*/*' })
      .to_return(status: 200, body: '', headers: {})

    stub_request(:post, "#{API_URL}/new-reg")
      .with(body: '{"protected":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp3ayI6eyJlIjoiQVFBQiIsImt0eS'\
                  'I6IlJTQSIsIm4iOiJxN0gtQ2txRHZ3ekx2OWRBZ05rSmQzM2FiVEpFa0ZHSjhXbGIxRnZ1Y1F6MEFYWX'\
                  'JwWUx5ajdOYUNyQm90V1NaR2pFSnRQZ1k1M0xWWU1ET1BiOTktLTZEazNXVGhkT203U01JTlZYWlZ1Ym'\
                  'hhNmtoY1pFWFA1NEdic0NzcFBmNm5OcUJCeEhDblV3V01GOElRcWkwTVdSNHFOeG1LZEVrcE56dGFCd0'\
                  'xLU0ZWUHNRMHRGeXJHellhOEw0TkJqZWUyaWlEdWM2bHlMTkp6MnhfUUZMQWZneGw1cXdFa05FVGxNNz'\
                  'JNQlRsTTNrR1k4UjN2RkVNVEhQSUtCM3VQcHdScE1qOEw2M1JLenpmcmM5Q0Y2TDRNaG01b05GUENndm'\
                  'JDRWF6T0ctTEpwM2Q4bVlTZjBERE5RNlhoX0NnTG5TbXAzVWVmckpiQVFUZDBpSk4xa21TaV9fQmxOR1'\
                  'JDS1dFZDgyZzA2aHgwbVRhOXVZZEQxMFNXaVF5UHZIbDRzWER3M0JMN0VpOVlPNHpoOUh6ZkpzUVhxY2'\
                  'hzQnZVZ2dEVG9IZVJwMnhmS0hEcmFFZ2JPX0FxaEMxRkdkTUtPUnJMWnBMQm1oamw0MFVvMWNLUXZsbl'\
                  'ZJZFJaQjU4QnoyZUhzNDVKN0ROYktsQm12cWZPQnJFN09nOHdEbFUzWFpIZ3dRZkt4TUhBV29Qc0d2RG'\
                  '1KRjRZdFRmZ0R4NmZWS2VNbng5cXpJQ0plRlZmYnkzaUc4dE9XUFNKWFZUcXZ2QlhiQnppT0h4bV9sOH'\
                  'pma3UwUmk3RXYwWUU2VEJGWDZiNDRES0FpVW9adkUwTm9taXhhYll2ZDAwWFFPNndOMF9pdkN6Tmc0VV'\
                  'ltaDlZUzJyM1E3YmloNFkyS3MyWllxdnNkazFnLWZiNGZRcyJ9LCJub25jZSI6bnVsbH0",'\
                  '"payload":"eyJyZXNvdXJjZSI6Im5ldy1yZWciLCJjb250YWN0IjpbIm1haWx0bzpmb29iYXJiYXpAZ'\
                  'XhhbXBsZS5jb20iXX0",'\
                  '"signature":"aQ6T0XVo9jS_jXlvQ6bjAfqcrMYpQTPE9_CD7v1hDBUzKpSoygAJmrbb0kSumMkWf-r'\
                  'acxG5i7tcD4ed32ap1OsWUoPGWhXkQifAqToYMdfBzjwaS_OfjPpFflPOZmUvOygtGt3LTsdhA27PCSC'\
                  'saZDlozz2143b00QhZ-gVkFRJEwOMN22ByOsL-1_R_UEp7mqwQKzeZ_nsW7japvGWcru13bzqiD2b069'\
                  'kwrfksnMIMSjFWnJPnxCLpY-DQn8kCBeJfljW-mOJyZFck1ko0KBiOEbY_k0IJ0aspwg9lGRLkVX-wWV'\
                  '8Q_e8gwoLjmaXouUxAl2E3wNInXRJkgDOMfEUSOHzxI6WFYLzhVKVl7ktP7zx21my2vL_J_nROTDaVIU'\
                  'qJgdUgEZ40KR_Kjd_pRKPcB8kHyKtDnCopmrPXLu0QCuHYAn_M-cYgkFOyvplJNodaZfKamLuwChywPl'\
                  'DC5tr1BQvdlUVp-cwr_C_KU-Kpkws924xI0ah8ksuwsHpkp2458aVEIeDEEw7FgHZXUPKXaJcBIHjQ1R'\
                  'vnm062Ub_4LR25TrKTgftDCftK2YtN4LA-jtlfOrdM47xZatAzhmFy_vFIIu_-phh5he0nn8Mx2byjsZ'\
                  '1M-DeW0Wl9_zxhhOo1gtmFhtguCKw3W0mdcdDZmhRleNS-HtYA0w41LA"}',
            headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                       'User-Agent' => ACME_USER_AGENT })
      .to_return(status: 200, body: '', headers: {})

    assert_nothing_raised do
      cg.register
    end
  end

  test 'register_with_privkey_in_db' do
    cg = LetsencryptPlugin::CertGenerator.new(private_key_in_db: true,
                                              endpoint: ENDPOINT_URL,
                                              domain: 'example.com',
                                              email: 'foobarbaz@example.com')
    assert !cg.nil?

    stub_request(:head, "#{API_URL}/new-reg")
      .with(headers: { 'Accept' => '*/*' })
      .to_return(status: 200, body: '', headers: {})

    stub_request(:post, "#{API_URL}/new-reg")
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
                       'User-Agent' => ACME_USER_AGENT })
      .to_return(status: 200, body: '', headers: {})

    assert_nothing_raised do
      cg.register
    end
  end

  test 'register_and_authorize' do
    cg = LetsencryptPlugin::CertGenerator.new(private_key: 'key/test_keyfile_4096.pem',
                                              endpoint: ENDPOINT_URL,
                                              domain: 'example.com',
                                              email: 'foobarbaz@example.com')
    assert !cg.nil?

    stub_request(:head, "#{API_URL}/new-reg")
      .with(headers: { 'Accept' => '*/*' })
      .to_return(status: 200, body: '', headers: {})

    protected_field = '"protected":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp3ayI6eyJlIjoiQVFBQiIsImt0eS'\
                  'I6IlJTQSIsIm4iOiJxN0gtQ2txRHZ3ekx2OWRBZ05rSmQzM2FiVEpFa0ZHSjhXbGIxRnZ1Y1F6MEFYWX'\
                  'JwWUx5ajdOYUNyQm90V1NaR2pFSnRQZ1k1M0xWWU1ET1BiOTktLTZEazNXVGhkT203U01JTlZYWlZ1Ym'\
                  'hhNmtoY1pFWFA1NEdic0NzcFBmNm5OcUJCeEhDblV3V01GOElRcWkwTVdSNHFOeG1LZEVrcE56dGFCd0'\
                  'xLU0ZWUHNRMHRGeXJHellhOEw0TkJqZWUyaWlEdWM2bHlMTkp6MnhfUUZMQWZneGw1cXdFa05FVGxNNz'\
                  'JNQlRsTTNrR1k4UjN2RkVNVEhQSUtCM3VQcHdScE1qOEw2M1JLenpmcmM5Q0Y2TDRNaG01b05GUENndm'\
                  'JDRWF6T0ctTEpwM2Q4bVlTZjBERE5RNlhoX0NnTG5TbXAzVWVmckpiQVFUZDBpSk4xa21TaV9fQmxOR1'\
                  'JDS1dFZDgyZzA2aHgwbVRhOXVZZEQxMFNXaVF5UHZIbDRzWER3M0JMN0VpOVlPNHpoOUh6ZkpzUVhxY2'\
                  'hzQnZVZ2dEVG9IZVJwMnhmS0hEcmFFZ2JPX0FxaEMxRkdkTUtPUnJMWnBMQm1oamw0MFVvMWNLUXZsbl'\
                  'ZJZFJaQjU4QnoyZUhzNDVKN0ROYktsQm12cWZPQnJFN09nOHdEbFUzWFpIZ3dRZkt4TUhBV29Qc0d2RG'\
                  '1KRjRZdFRmZ0R4NmZWS2VNbng5cXpJQ0plRlZmYnkzaUc4dE9XUFNKWFZUcXZ2QlhiQnppT0h4bV9sOH'\
                  'pma3UwUmk3RXYwWUU2VEJGWDZiNDRES0FpVW9adkUwTm9taXhhYll2ZDAwWFFPNndOMF9pdkN6Tmc0VV'\
                  'ltaDlZUzJyM1E3YmloNFkyS3MyWllxdnNkazFnLWZiNGZRcyJ9LCJub25jZSI6bnVsbH0"'
    stub_request(:post, "#{API_URL}/new-reg")
      .with(body: "{#{protected_field},"\
                  '"payload":"eyJyZXNvdXJjZSI6Im5ldy1yZWciLCJjb250YWN0IjpbIm1haWx0bzpmb29iYXJiYXpAZ'\
                  'XhhbXBsZS5jb20iXX0",'\
                  '"signature":"aQ6T0XVo9jS_jXlvQ6bjAfqcrMYpQTPE9_CD7v1hDBUzKpSoygAJmrbb0kSumMkWf-r'\
                  'acxG5i7tcD4ed32ap1OsWUoPGWhXkQifAqToYMdfBzjwaS_OfjPpFflPOZmUvOygtGt3LTsdhA27PCSC'\
                  'saZDlozz2143b00QhZ-gVkFRJEwOMN22ByOsL-1_R_UEp7mqwQKzeZ_nsW7japvGWcru13bzqiD2b069'\
                  'kwrfksnMIMSjFWnJPnxCLpY-DQn8kCBeJfljW-mOJyZFck1ko0KBiOEbY_k0IJ0aspwg9lGRLkVX-wWV'\
                  '8Q_e8gwoLjmaXouUxAl2E3wNInXRJkgDOMfEUSOHzxI6WFYLzhVKVl7ktP7zx21my2vL_J_nROTDaVIU'\
                  'qJgdUgEZ40KR_Kjd_pRKPcB8kHyKtDnCopmrPXLu0QCuHYAn_M-cYgkFOyvplJNodaZfKamLuwChywPl'\
                  'DC5tr1BQvdlUVp-cwr_C_KU-Kpkws924xI0ah8ksuwsHpkp2458aVEIeDEEw7FgHZXUPKXaJcBIHjQ1R'\
                  'vnm062Ub_4LR25TrKTgftDCftK2YtN4LA-jtlfOrdM47xZatAzhmFy_vFIIu_-phh5he0nn8Mx2byjsZ'\
                  '1M-DeW0Wl9_zxhhOo1gtmFhtguCKw3W0mdcdDZmhRleNS-HtYA0w41LA"}',
            headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                       'User-Agent' => ACME_USER_AGENT })
      .to_return(status: 200, body: '', headers: {})

    stub_request(:post, "#{API_URL}/new-authz")
      .with(body: "{#{protected_field},"\
                  '"payload":"eyJyZXNvdXJjZSI6Im5ldy1hdXRoeiIsImlkZW50aWZpZXIiOnsidHlwZSI6ImRucyIsI'\
                  'nZhbHVlIjoiZXhhbXBsZS5jb20ifX0",'\
                  '"signature":"NIo2YSDVmY-ILSdUXu4r1sBi31YYEHGvAz0t9IskSjCDl3A2C7fKXXejxLEU9aHvjR8'\
                  '9ZwrQtdDjhSVvZ5tCOkN8UhZ_jo2Y9iDIoNijd7t11jCxiv9epgQ83cUXtqgYLQnfpNNFlxd24yyLNNe'\
                  'K6NM4mIhf5fyji6skTOrv4TPg4ZZzx107dmPmGsKQpSo2uRb1bV6H63qOwqjfp4LYM_HrHTH-L_HQTgt'\
                  '1fV4pmlTYlmaK__OLgxBXdVFgSN2yAUXPl3b9xYsGq3yEdXlGFv_f2iNbfhhiFHl_ZbRsjbLY5QU5TRa'\
                  'Y6w5LjVkMwNLuusAeR5SwkOjGYQw-PQ303xuCx2WhlcIVlz06Lex9zrYH7TVc1Tfl5aiaqw4lABJoFu8'\
                  'YLWx83gQZbeyBJJ612e_oNqsbmd0RWytXzS-qydLmpjl2KS7U_877JIoZPePwqzbuNoUmeVfqQcCGcpM'\
                  't1atBAoBVgOKW5cWlEhZD4BRY_q-dX2hcR-7T1suLdMpEc1b_JQr0EVxgz0rZWcE3xAtlQLYZtC7n_nW'\
                  'B4EiQzRiiP1mgPRwdmASmAAMp7ToW53lYh-vLxpHX7CzLdug2AuvFkG6ajaGFMzZaJ4dyxf0GbznSNyV'\
                  'ulEJlxSt81MVthCX3JjUtRDcJHZx6tQFR1Gm1RUDE7Sob0Xe6jZKfqRE"}',
            headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                       'User-Agent' => ACME_USER_AGENT })
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
                       " \"uri\": \"#{API_URL}/challenge/JmusiS7mAL_OZ1tIbwQxpYadpM9E3Azbywa6KSveuEk/93\","\
                       ' "token":"-Jbrff2stnTiZXFFKJHXtYrZof2dqlQaegRbeG1t6BY"'\
                       ' }'\
                       ' ],'\
                       ' "combinations":[[0]]'\
                       '}',
                 headers: { 'Content-Type' => 'application/json',
                            'Link' => "<#{API_URL}/new-cert>;rel=\"next\"",
                            'Location' => "#{API_URL}/authz/JmusiS7mAL_OZ1tIbwQxpYadpM9E3Azbywa6KSveuEk",
                            'Replay-Nonce' => 'Hdhg8ovViG7ipkQrQRW2dsDbK5vxhGd_4T9HDqg3u4c' })

    assert_nothing_raised do
      cg.register
      cg.authorize
    end
  end
end
