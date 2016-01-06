require 'letsencrypt_plugin/engine'
require 'letsencrypt_plugin/file_output'
require 'letsencrypt_plugin/heroku_output'
require 'letsencrypt_plugin/file_store'
require 'letsencrypt_plugin/database_store'
require 'openssl'
require 'acme/client'

module LetsencryptPlugin
  class CertGenerator
    def initialize
      Rails.logger.info('Loading private key...')
      private_key = File.join(Rails.root, CONFIG[:private_key])
      begin
        @client ||= Acme::Client.new(private_key: OpenSSL::PKey::RSA.new(File.read(private_key)), endpoint: CONFIG[:endpoint])
      rescue Exception => e
        Rails.logger.error("Failed to load private key: '#{private_key}'")
        Rails.logger.error("#{e}")
        raise e
      end
    end

    def register
      Rails.logger.info('Trying to register at Let\'s Encrypt service...')
      begin
        registration = @client.register(contact: "mailto:#{CONFIG[:email]}")
        registration.agree_terms
        Rails.logger.info('Registration succeed.')
      rescue
        Rails.logger.info('Already registered.')
      end
    end

    def authorize
      Rails.logger.info('Sending authorization request...')
      @authorization = @client.authorize(domain: CONFIG[:domain])
    end

    def store_challenge(challenge)
      if CONFIG[:challenge_dir_name].nil? || CONFIG[:challenge_dir_name].empty?
        DatabaseStore.new(challenge.file_content).store
      else
        FileStore.new(challenge.file_content).store
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
        return HerokuOutput.new(certificate).output unless ENV['DYNO'].nil?
        output_dir = File.join(Rails.root, CONFIG[:output_cert_dir])
        return FileOutput.new(certificate, output_dir).output if File.directory?(output_dir)
        Rails.logger.error("Output directory: '#{output_dir}' does not exist!")
      end unless certificate.nil?
    end

    def generate_certificate
      register
      authorize
      handle_challenge
      request_challenge_verification
      begin
        # We can now request a certificate
        Rails.logger.info('Creating CSR...')
        save_certificate(client.new_certificate(Acme::Client::CertificateRequest.new(names: [CONFIG[:domain]])))

        Rails.logger.info('Certificate has been generated.')
      end if valid_verification_status
    end
  end
end
