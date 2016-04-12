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
      .with(body: '{"protected":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIm5vbmNlIjpudWxsLCJ'\
                 'qd2siOnsia3R5IjoiUlNBIiwiZSI6IkFRQUIiLCJuIjoicTdILUNrcUR2d3pMdjlkQWdO'\
                 'a0pkMzNhYlRKRWtGR0o4V2xiMUZ2dWNRejBBWFlycFlMeWo3TmFDckJvdFdTWkdqRUp0U'\
                 'GdZNTNMVllNRE9QYjk5LS02RGszV1RoZE9tN1NNSU5WWFpWdWJoYTZraGNaRVhQNTRHYn'\
                 'NDc3BQZjZuTnFCQnhIQ25Vd1dNRjhJUXFpME1XUjRxTnhtS2RFa3BOenRhQndMS1NGVlB'\
                 'zUTB0RnlyR3pZYThMNE5CamVlMmlpRHVjNmx5TE5KejJ4X1FGTEFmZ3hsNXF3RWtORVRs'\
                 'TTcyTUJUbE0za0dZOFIzdkZFTVRIUElLQjN1UHB3UnBNajhMNjNSS3p6ZnJjOUNGNkw0T'\
                 'WhtNW9ORlBDZ3ZiQ0Vhek9HLUxKcDNkOG1ZU2YwREROUTZYaF9DZ0xuU21wM1VlZnJKYk'\
                 'FRVGQwaUpOMWttU2lfX0JsTkdSQ0tXRWQ4MmcwNmh4MG1UYTl1WWREMTBTV2lReVB2SGw'\
                 '0c1hEdzNCTDdFaTlZTzR6aDlIemZKc1FYcWNoc0J2VWdnRFRvSGVScDJ4ZktIRHJhRWdi'\
                 'T19BcWhDMUZHZE1LT1JyTFpwTEJtaGpsNDBVbzFjS1F2bG5WSWRSWkI1OEJ6MmVIczQ1S'\
                 'jdETmJLbEJtdnFmT0JyRTdPZzh3RGxVM1haSGd3UWZLeE1IQVdvUHNHdkRtSkY0WXRUZm'\
                 'dEeDZmVktlTW54OXF6SUNKZUZWZmJ5M2lHOHRPV1BTSlhWVHF2dkJYYkJ6aU9IeG1fbDh'\
                 '6Zmt1MFJpN0V2MFlFNlRCRlg2YjQ0REtBaVVvWnZFME5vbWl4YWJZdmQwMFhRTzZ3TjBf'\
                 'aXZDek5nNFVZbWg5WVMycjNRN2JpaDRZMktzMlpZcXZzZGsxZy1mYjRmUXMifX0",'\
                 '"payload":"eyJyZXNvdXJjZSI6Im5ldy1yZWciLCJjb250YWN0IjpbIm1haWx0bzpmb2'\
                 '9iYXJiYXpAZXhhbXBsZS5jb20iXX0",'\
                 '"signature":"qDseMT523-4XoGbgh2Qq0n7wzsvFJOp97ERrEWmBXqmPX2lJLZMIUrmm'\
                 'JeW-_Yz4tI1TZ3NVX9WFSdyvq3Z67H776WkS8mAm5cc6LK6HcrScl_y9Sm3bqyipVD1EF'\
                 'AkQxJixNOaWIoX-fSXZNXuchX4AfdKuDt1fg2_d2NzX1aLk4FOYxiko6i4HyvuA4Jp11q'\
                 'JOldhPMQ5Vqrm4QgMd4CFHVEd9tK1-03ejnTgcjrtshrdelVoWLxEoh7_EAeB6oElA-V_'\
                 '72eswPyhf_rfrRKbl8rHbrAS6UvBuKcdJfQFyWr1kXqTMw05EookJlbODQTpvzzVMIT9x'\
                 'ANXvFQrWLeOgQup1tN1X-lIZA9leud3tLduCcG3HgR8tM7EdO7Ka0PtsHLkVrZuc6Arcu'\
                 '0s4KY3_fImNi3UYUf1PvnP_JbAh2HKaugckqnmzy7F06r-rO0PEgNfMO5FOdJG1Fn2Csb'\
                 'jUZw8jb1XK3CAwKXOjfu6fFxyvf7fxbgi4Y-OJWHxFM-6r-zFlTWs3lJbeSr80ZWdumbJ'\
                 'h_i6XUN0FvyhbulMisPA7Tkw6Yk27nitRMVKDbswdmCurdJWc3T5Vi3zZ3V_Lshos9WVO'\
                 'EsEE-TKTlIJv4dI7OpqUsRsD_jOOSxTeE7ZJC6A0jZsB0KSwLOdJJ42DDD5D8KFz9aIiX'\
                 '8bEppg"}',
            headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3' })
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
      .with(body: '{"protected":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIm5vbmNlIjpudWxsLCJ'\
                 'qd2siOnsia3R5IjoiUlNBIiwiZSI6IkFRQUIiLCJuIjoicTdILUNrcUR2d3pMdjlkQWdO'\
                 'a0pkMzNhYlRKRWtGR0o4V2xiMUZ2dWNRejBBWFlycFlMeWo3TmFDckJvdFdTWkdqRUp0U'\
                 'GdZNTNMVllNRE9QYjk5LS02RGszV1RoZE9tN1NNSU5WWFpWdWJoYTZraGNaRVhQNTRHYn'\
                 'NDc3BQZjZuTnFCQnhIQ25Vd1dNRjhJUXFpME1XUjRxTnhtS2RFa3BOenRhQndMS1NGVlB'\
                 'zUTB0RnlyR3pZYThMNE5CamVlMmlpRHVjNmx5TE5KejJ4X1FGTEFmZ3hsNXF3RWtORVRs'\
                 'TTcyTUJUbE0za0dZOFIzdkZFTVRIUElLQjN1UHB3UnBNajhMNjNSS3p6ZnJjOUNGNkw0T'\
                 'WhtNW9ORlBDZ3ZiQ0Vhek9HLUxKcDNkOG1ZU2YwREROUTZYaF9DZ0xuU21wM1VlZnJKYk'\
                 'FRVGQwaUpOMWttU2lfX0JsTkdSQ0tXRWQ4MmcwNmh4MG1UYTl1WWREMTBTV2lReVB2SGw'\
                 '0c1hEdzNCTDdFaTlZTzR6aDlIemZKc1FYcWNoc0J2VWdnRFRvSGVScDJ4ZktIRHJhRWdi'\
                 'T19BcWhDMUZHZE1LT1JyTFpwTEJtaGpsNDBVbzFjS1F2bG5WSWRSWkI1OEJ6MmVIczQ1S'\
                 'jdETmJLbEJtdnFmT0JyRTdPZzh3RGxVM1haSGd3UWZLeE1IQVdvUHNHdkRtSkY0WXRUZm'\
                 'dEeDZmVktlTW54OXF6SUNKZUZWZmJ5M2lHOHRPV1BTSlhWVHF2dkJYYkJ6aU9IeG1fbDh'\
                 '6Zmt1MFJpN0V2MFlFNlRCRlg2YjQ0REtBaVVvWnZFME5vbWl4YWJZdmQwMFhRTzZ3TjBf'\
                 'aXZDek5nNFVZbWg5WVMycjNRN2JpaDRZMktzMlpZcXZzZGsxZy1mYjRmUXMifX0",'\
                 '"payload":"eyJyZXNvdXJjZSI6Im5ldy1yZWciLCJjb250YWN0IjpbIm1haWx0bzpmb2'\
                 '9iYXJiYXpAZXhhbXBsZS5jb20iXX0",'\
                 '"signature":"qDseMT523-4XoGbgh2Qq0n7wzsvFJOp97ERrEWmBXqmPX2lJLZMIUrmm'\
                 'JeW-_Yz4tI1TZ3NVX9WFSdyvq3Z67H776WkS8mAm5cc6LK6HcrScl_y9Sm3bqyipVD1EF'\
                 'AkQxJixNOaWIoX-fSXZNXuchX4AfdKuDt1fg2_d2NzX1aLk4FOYxiko6i4HyvuA4Jp11q'\
                 'JOldhPMQ5Vqrm4QgMd4CFHVEd9tK1-03ejnTgcjrtshrdelVoWLxEoh7_EAeB6oElA-V_'\
                 '72eswPyhf_rfrRKbl8rHbrAS6UvBuKcdJfQFyWr1kXqTMw05EookJlbODQTpvzzVMIT9x'\
                 'ANXvFQrWLeOgQup1tN1X-lIZA9leud3tLduCcG3HgR8tM7EdO7Ka0PtsHLkVrZuc6Arcu'\
                 '0s4KY3_fImNi3UYUf1PvnP_JbAh2HKaugckqnmzy7F06r-rO0PEgNfMO5FOdJG1Fn2Csb'\
                 'jUZw8jb1XK3CAwKXOjfu6fFxyvf7fxbgi4Y-OJWHxFM-6r-zFlTWs3lJbeSr80ZWdumbJ'\
                 'h_i6XUN0FvyhbulMisPA7Tkw6Yk27nitRMVKDbswdmCurdJWc3T5Vi3zZ3V_Lshos9WVO'\
                 'EsEE-TKTlIJv4dI7OpqUsRsD_jOOSxTeE7ZJC6A0jZsB0KSwLOdJJ42DDD5D8KFz9aIiX'\
                 '8bEppg"}',
            headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3' })
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

    protected_field = '"protected":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIm5vbmNlIjpudWxsLCJ'\
                  'qd2siOnsia3R5IjoiUlNBIiwiZSI6IkFRQUIiLCJuIjoicTdILUNrcUR2d3pMdjlkQWdO'\
                  'a0pkMzNhYlRKRWtGR0o4V2xiMUZ2dWNRejBBWFlycFlMeWo3TmFDckJvdFdTWkdqRUp0U'\
                  'GdZNTNMVllNRE9QYjk5LS02RGszV1RoZE9tN1NNSU5WWFpWdWJoYTZraGNaRVhQNTRHYn'\
                  'NDc3BQZjZuTnFCQnhIQ25Vd1dNRjhJUXFpME1XUjRxTnhtS2RFa3BOenRhQndMS1NGVlB'\
                  'zUTB0RnlyR3pZYThMNE5CamVlMmlpRHVjNmx5TE5KejJ4X1FGTEFmZ3hsNXF3RWtORVRs'\
                  'TTcyTUJUbE0za0dZOFIzdkZFTVRIUElLQjN1UHB3UnBNajhMNjNSS3p6ZnJjOUNGNkw0T'\
                  'WhtNW9ORlBDZ3ZiQ0Vhek9HLUxKcDNkOG1ZU2YwREROUTZYaF9DZ0xuU21wM1VlZnJKYk'\
                  'FRVGQwaUpOMWttU2lfX0JsTkdSQ0tXRWQ4MmcwNmh4MG1UYTl1WWREMTBTV2lReVB2SGw'\
                  '0c1hEdzNCTDdFaTlZTzR6aDlIemZKc1FYcWNoc0J2VWdnRFRvSGVScDJ4ZktIRHJhRWdi'\
                  'T19BcWhDMUZHZE1LT1JyTFpwTEJtaGpsNDBVbzFjS1F2bG5WSWRSWkI1OEJ6MmVIczQ1S'\
                  'jdETmJLbEJtdnFmT0JyRTdPZzh3RGxVM1haSGd3UWZLeE1IQVdvUHNHdkRtSkY0WXRUZm'\
                  'dEeDZmVktlTW54OXF6SUNKZUZWZmJ5M2lHOHRPV1BTSlhWVHF2dkJYYkJ6aU9IeG1fbDh'\
                  '6Zmt1MFJpN0V2MFlFNlRCRlg2YjQ0REtBaVVvWnZFME5vbWl4YWJZdmQwMFhRTzZ3TjBf'\
                  'aXZDek5nNFVZbWg5WVMycjNRN2JpaDRZMktzMlpZcXZzZGsxZy1mYjRmUXMifX0"'

    stub_request(:post, 'https://acme-staging.api.letsencrypt.org/acme/new-reg')
      .with(body: "{#{protected_field},"\
                  '"payload":"eyJyZXNvdXJjZSI6Im5ldy1yZWciLCJjb250YWN0IjpbIm1haWx0bzpmb2'\
                  '9iYXJiYXpAZXhhbXBsZS5jb20iXX0",'\
                  '"signature":"qDseMT523-4XoGbgh2Qq0n7wzsvFJOp97ERrEWmBXqmPX2lJLZMIUrmm'\
                  'JeW-_Yz4tI1TZ3NVX9WFSdyvq3Z67H776WkS8mAm5cc6LK6HcrScl_y9Sm3bqyipVD1EF'\
                  'AkQxJixNOaWIoX-fSXZNXuchX4AfdKuDt1fg2_d2NzX1aLk4FOYxiko6i4HyvuA4Jp11q'\
                  'JOldhPMQ5Vqrm4QgMd4CFHVEd9tK1-03ejnTgcjrtshrdelVoWLxEoh7_EAeB6oElA-V_'\
                  '72eswPyhf_rfrRKbl8rHbrAS6UvBuKcdJfQFyWr1kXqTMw05EookJlbODQTpvzzVMIT9x'\
                  'ANXvFQrWLeOgQup1tN1X-lIZA9leud3tLduCcG3HgR8tM7EdO7Ka0PtsHLkVrZuc6Arcu'\
                  '0s4KY3_fImNi3UYUf1PvnP_JbAh2HKaugckqnmzy7F06r-rO0PEgNfMO5FOdJG1Fn2Csb'\
                  'jUZw8jb1XK3CAwKXOjfu6fFxyvf7fxbgi4Y-OJWHxFM-6r-zFlTWs3lJbeSr80ZWdumbJ'\
                  'h_i6XUN0FvyhbulMisPA7Tkw6Yk27nitRMVKDbswdmCurdJWc3T5Vi3zZ3V_Lshos9WVO'\
                  'EsEE-TKTlIJv4dI7OpqUsRsD_jOOSxTeE7ZJC6A0jZsB0KSwLOdJJ42DDD5D8KFz9aIiX'\
                  '8bEppg"}',
            headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3' })
      .to_return(status: 200, body: '', headers: {})

    stub_request(:post, 'https://acme-staging.api.letsencrypt.org/acme/new-authz')
      .with(body: "{#{protected_field},"\
                  '"payload":"eyJyZXNvdXJjZSI6Im5ldy1hdXRoeiIsImlkZW50aWZpZXIiOnsidHlwZS'\
                  'I6ImRucyIsInZhbHVlIjoiZXhhbXBsZS5jb20ifX0",'\
                  '"signature":"Fiam5Q6wPhO3Hbj3AR8-vUNPeuEEZ657vIDkX37WZ-WppkTce_Yr0MLe'\
                  'hrnbna1SaC7Blg9E5ZawCzwQUPuUJZjBM7zn3czc4xb0KUxOpGxpa4N4dWzZMHlC2RfQk'\
                  'mBda7qMID3ewAwANSsptpL8SzgnQgpUBTRyhE6CIbszKkwM0sJQKGM5HdZV3BVOTXRR5n'\
                  'otWQA98kfaUKpSbjUNNZgKIOLlqyn8bOMUAZKR-VBw8MPOSbiXH_BBqOyfPjCAyg0wLuZ'\
                  'mfFKl3oi_4jq7XEnowu9Lq5izFf3EiFsf-wksp9zoqqfGPdtPkLKG6PFrYm0jhM2XOP6m'\
                  'bFkrTRcLtlKNp1xk8CEPHuNc_yx7nokTMDdErJQZleKPipygDsxrhUchK-w8ajjwqcItQ'\
                  'Ndlitlo4J-PpSuwa3bIubVNzBHofjuEr1Xq3bCtT7QUAwhmvAbgkNaFoNcpseUR8W-1nY'\
                  'eUOkSq1yTJ9RUVMNRuYraOPDO1SbuwGxLaHRs-p-W3cfvfLUzv3fKOam_h061_8rtTIa0'\
                  'hjj_PAB6X1hiJRq62wpUCYuaEnUNqzRj6gIJn2OVYlWow3VsMkuZ2j_O3guPFALYF-f_W'\
                  'hndWSLAi8XN7sJaGlo_oxpzVwi33GPHMp9InN71Y9Gt3-stDyKMJIsU2LRpef2wICGwWs'\
                  '0wp7uU"}',
            headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3' })
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
