require 'test_helper'

class LetsencryptPluginTest < ActiveSupport::TestCase
  include Mocha::Integration::MiniTest

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
end
