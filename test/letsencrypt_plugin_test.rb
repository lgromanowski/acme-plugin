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

    cg.client = Acme::Client.new(private_key: cg.load_private_key, endpoint: cg.options[:endpoint])
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
                  '"signature":"nLsyF3pozzqEZZL_117-ku0re_z_i900UWVNbzGTe_xawyewgZNj0whPOcBd0WRs2aL'\
                  'XBvsZsVGdoH3R6YpSLfJntoaz4PdtyeIq_XZroT6nUq1M3KM9MIOMkclONXAWJMdhaP5EYoai72i2-A7'\
                  'H6JLKfsCKMV1dgc6SrPCpZiAkyuHxOlwJvyuo5Eg9z7FG6TRQ__EoaBYs0FrtO8PN7dTRK3QhPF3SZ4n'\
                  'Xq1Z4qX7Y_k5XW-Tah3c1-IratC8WGeU_j5ULBw4gRMsycHJCQI5c_c_l6MDniGKvY23kMzKDQ5eoKgL'\
                  'OXKd7J06_FQjbZPcMh-1Xsi2I2pDM1Ftepav-H7YRtgAlQs5-9JRUc7h6lUWCBTV3CLAbOgNTIRMcIuS'\
                  'WmpoCzMBnuQfCvQGK6BNT0okqiHbbQzgK4qf_M0TMx5wVLgwM9snt70KpJ3XjcFSBXpC9QuwbFwTpwtg'\
                  'D0APL1PCa-h45wAtsxJaXcIYcAnAHaaL0ghd4IkqtdFbZqydlm1WpdcLtdF5mgXm72OaGT-JRxWfZAII'\
                  'Rm_aby34oBlb14Q3WFV339nT9sukZGrTAz9fRy2oRKzFVLLYBfft0fRAu1YcELrWHUtjQBi8KCrCkXjh'\
                  'k1Lvrtr8xAxot1Hi-Gf1FkApH443cqB15H7S0W099h5KzaUVQouTg9iE"}',
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

    cg.client = Acme::Client.new(private_key: cg.load_private_key, endpoint: cg.options[:endpoint])
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
                  '"signature":"nLsyF3pozzqEZZL_117-ku0re_z_i900UWVNbzGTe_xawyewgZNj0whPOcBd0WRs2aL'\
                  'XBvsZsVGdoH3R6YpSLfJntoaz4PdtyeIq_XZroT6nUq1M3KM9MIOMkclONXAWJMdhaP5EYoai72i2-A7'\
                  'H6JLKfsCKMV1dgc6SrPCpZiAkyuHxOlwJvyuo5Eg9z7FG6TRQ__EoaBYs0FrtO8PN7dTRK3QhPF3SZ4n'\
                  'Xq1Z4qX7Y_k5XW-Tah3c1-IratC8WGeU_j5ULBw4gRMsycHJCQI5c_c_l6MDniGKvY23kMzKDQ5eoKgL'\
                  'OXKd7J06_FQjbZPcMh-1Xsi2I2pDM1Ftepav-H7YRtgAlQs5-9JRUc7h6lUWCBTV3CLAbOgNTIRMcIuS'\
                  'WmpoCzMBnuQfCvQGK6BNT0okqiHbbQzgK4qf_M0TMx5wVLgwM9snt70KpJ3XjcFSBXpC9QuwbFwTpwtg'\
                  'D0APL1PCa-h45wAtsxJaXcIYcAnAHaaL0ghd4IkqtdFbZqydlm1WpdcLtdF5mgXm72OaGT-JRxWfZAII'\
                  'Rm_aby34oBlb14Q3WFV339nT9sukZGrTAz9fRy2oRKzFVLLYBfft0fRAu1YcELrWHUtjQBi8KCrCkXjh'\
                  'k1Lvrtr8xAxot1Hi-Gf1FkApH443cqB15H7S0W099h5KzaUVQouTg9iE"}',
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

    cg.client = Acme::Client.new(private_key: cg.load_private_key, endpoint: cg.options[:endpoint])
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
                  '"signature":"nLsyF3pozzqEZZL_117-ku0re_z_i900UWVNbzGTe_xawyewgZNj0whPOcBd0WRs2aL'\
                  'XBvsZsVGdoH3R6YpSLfJntoaz4PdtyeIq_XZroT6nUq1M3KM9MIOMkclONXAWJMdhaP5EYoai72i2-A7'\
                  'H6JLKfsCKMV1dgc6SrPCpZiAkyuHxOlwJvyuo5Eg9z7FG6TRQ__EoaBYs0FrtO8PN7dTRK3QhPF3SZ4n'\
                  'Xq1Z4qX7Y_k5XW-Tah3c1-IratC8WGeU_j5ULBw4gRMsycHJCQI5c_c_l6MDniGKvY23kMzKDQ5eoKgL'\
                  'OXKd7J06_FQjbZPcMh-1Xsi2I2pDM1Ftepav-H7YRtgAlQs5-9JRUc7h6lUWCBTV3CLAbOgNTIRMcIuS'\
                  'WmpoCzMBnuQfCvQGK6BNT0okqiHbbQzgK4qf_M0TMx5wVLgwM9snt70KpJ3XjcFSBXpC9QuwbFwTpwtg'\
                  'D0APL1PCa-h45wAtsxJaXcIYcAnAHaaL0ghd4IkqtdFbZqydlm1WpdcLtdF5mgXm72OaGT-JRxWfZAII'\
                  'Rm_aby34oBlb14Q3WFV339nT9sukZGrTAz9fRy2oRKzFVLLYBfft0fRAu1YcELrWHUtjQBi8KCrCkXjh'\
                  'k1Lvrtr8xAxot1Hi-Gf1FkApH443cqB15H7S0W099h5KzaUVQouTg9iE"}',
            headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                       'User-Agent' => 'Faraday v0.9.2' })
      .to_return(status: 200, body: '', headers: {})

    stub_request(:post, 'https://acme-staging.api.letsencrypt.org/acme/new-authz')
      .with(body: "{#{protected_field},"\
                  '"payload":"eyJyZXNvdXJjZSI6Im5ldy1hdXRoeiIsImlkZW50aWZpZXIiOnsidHlwZSI6ImRucyIsI'\
                  'nZhbHVlIjoiZXhhbXBsZS5jb20ifX0",'\
                  '"signature":"HT-zZ3TtjW2fYhExfb0nGvayaBCMHj_C7PUncZH3I3FOCNspsbbuTSsdFYED6pJgOOW'\
                  'itveFBMRl6rOnINIMO1h44-N_iDi8ff9eFwSMEFXcCxF0TR9pEESzvqv5WKhGY9BmY_gl5AEFb6tNMWy'\
                  '2DIMJFyki5IwhTiILwfwFt_Xn74SPpjZ8VzO5h-gcBRP8wkHKW7K78jEP8ySuUz0zMinsyba7uLYWNJ2'\
                  'r5Qt-gpBE603nch28G00kZuynN-ehCe6RIBsZ7vDyLp9K-V6MZ2P8_VCjcL69Fp06CDT_Nod_jNcRrZb'\
                  '48n1_hL0kbkpD945oMdlgPOc1U1gPmkG6kboaOXMe7HS63fwMyreMyQj8SQVPXTRvAtfUVKzLL5hJJ-i'\
                  'AWcj4KdN34cfuKBkodRuc_jtc0jZKtOanMwVKcJ_QFlYzWeVoCaqojBHhrGGkFZ4XZ2mrzRQ1yZV9yaE'\
                  'r-aTH7zIMb30c2hwHuMt33hpT7H8abp-oOFvB5CkS4VsKYSpr8CPGM4J2zv8IyPFv4RrA4_TJ5Ev8Ang'\
                  'DXPj_4b8BrzLFu6UOMi3YgjcmUiVuH4RXtDi166s2vBtak9lIVAleJWZQ1sbuKgc8ByyQHGgVN0XjnLX'\
                  'BNIzEjJQNlyj7MgGGhGBOakqPqykaZRNQqnuBOpwM2zvzY1ZqGokCCXI"}',
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
