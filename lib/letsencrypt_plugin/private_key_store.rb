require 'openssl'

class PrivateKeyStore

  def initialize(private_key)
    # this should eventually be any one of many backends?
    # these could then encapsulate the method of retrieving the
    # RSA key string. see: http://hawkins.io/2013/10/implementing_the_repository_pattern/
    @private_key = private_key
  end

  def retrieve
    pk = OpenSSL::PKey::RSA.new(@private_key)
    raise "Invalid key size: #{pk.n.num_bits}. Required size is between 2048 - 4096 bits" unless valid_key_size?(pk)
    pk
  rescue OpenSSL::PKey::RSAError => e
    raise "#{pk} is not a valid private key identifier"
  end

  private 

  def valid_key_size?(key)
    key.n.num_bits >= 2048 && key.n.num_bits <= 4096
  end

end
