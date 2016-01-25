require 'letsencrypt_plugin/engine'
require 'letsencrypt_plugin/file_output'
require 'letsencrypt_plugin/heroku_output'
require 'letsencrypt_plugin/file_store'
require 'letsencrypt_plugin/database_store'
require 'openssl'
require 'acme/client'

module LetsencryptPlugin
  class CertGenerator
    attr_reader :options
    attr_writer :client

    def initialize(options = {})
      @options = options
      @options.freeze
    end

    def authorize_and_handle_challenge(domains)
      result = false
      domains.each do |domain|
        authorize(domain)
        handle_challenge
        request_challenge_verification
        result = valid_verification_status
        break unless result
      end
      result
    end

    def generate_certificate
      register
      domains = @options[:domain].split(' ')
      return unless authorize_and_handle_challenge(domains)
      # We can now request a certificate
      Rails.logger.info('Creating CSR...')
      save_certificate(@client.new_certificate(Acme::Client::CertificateRequest.new(names: domains)))
      Rails.logger.info('Certificate has been generated.')
    end

    def client
      @client ||= Acme::Client.new(private_key: load_private_key, endpoint: @options[:endpoint])
    rescue Exception => e
      Rails.logger.error(e.to_s)
      raise e
    end

    def valid_key_size?(key)
      key.n.num_bits >= 2048 && key.n.num_bits <= 4096
    end

    def privkey_path
      fail 'Private key is not set, please check your '\
        'config/letsencrypt_plugin.yml file!' if @options[:private_key].nil? || @options[:private_key].empty?
      File.join(Rails.root, @options[:private_key])
    end

    def open_priv_key
      private_key_path = privkey_path
      fail "Can not open private key: #{private_key_path}" unless File.exist?(private_key_path) && !File.directory?(private_key_path)
      OpenSSL::PKey::RSA.new(File.read(private_key_path))
    end

    def load_private_key
      Rails.logger.info('Loading private key...')
      private_key = open_priv_key
      fail "Invalid key size: #{private_key.n.num_bits}." \
        ' Required size is between 2048 - 4096 bits' unless valid_key_size?(private_key)
      private_key
    end

    def register
      Rails.logger.info('Trying to register at Let\'s Encrypt service...')
      registration = client.register(contact: "mailto:#{@options[:email]}")
      registration.agree_terms
      Rails.logger.info('Registration succeed.')
    rescue
      Rails.logger.info('Already registered.')
    end

    def common_domain_name
      @domain ||= @options[:domain].split(' ').first.to_s
    end

    def authorize(domain = common_domain_name)
      Rails.logger.info("Sending authorization request for: #{domain}...")
      @authorization = client.authorize(domain: domain)
    end

    def store_challenge(challenge)
      if @options[:challenge_dir_name].nil? || @options[:challenge_dir_name].empty?
        DatabaseStore.new(challenge.file_content).store
      else
        FileStore.new(challenge.file_content, @options[:challenge_dir_name]).store
      end
      sleep(2)
    end

    def handle_challenge
      @challenge = @authorization.http01
      store_challenge(@challenge)
    end

    def request_challenge_verification
      @challenge.request_verification
    end

    def wait_for_status(challenge)
      Rails.logger.info('Waiting for challenge status...')
      counter = 0
      while challenge.verify_status == 'pending' && counter < 10
        sleep(1)
        counter += 1
      end
    end

    def valid_verification_status
      wait_for_status(@challenge)
      begin
        Rails.logger.error('Challenge verification failed! ' \
          "Error: #{@challenge.error['type']}: #{@challenge.error['detail']}")
        return false
      end unless @challenge.verify_status == 'valid'
      true
    end

    # Save the certificate and key
    def save_certificate(certificate)
      begin
        return HerokuOutput.new(common_domain_name, certificate).output unless ENV['DYNO'].nil?
        output_dir = File.join(Rails.root, @options[:output_cert_dir])
        return FileOutput.new(common_domain_name, certificate, output_dir).output if File.directory?(output_dir)
        Rails.logger.error("Output directory: '#{output_dir}' does not exist!")
      end unless certificate.nil?
    end
  end
end
