require 'letsencrypt_plugin/engine'
require 'letsencrypt_plugin/output'
require 'letsencrypt_plugin/file_output'
require 'letsencrypt_plugin/heroku_output'
require 'openssl'
require 'acme/client'

module LetsencryptPlugin
  class CertGenerator
    def initialize
      Rails.logger.info('Loading private key...')
      @client ||= Acme::Client.new(private_key: OpenSSL::PKey::RSA.new(File.read(File.join(Rails.root, CONFIG[:private_key]))),
                                   endpoint: CONFIG[:endpoint])
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

    def handle_challenge
      @challenge = @authorization.http01
      store_challenge(challenge)
    end

    def challenge_verification
      @challenge.request_verification # => true
      wait_for_status(@challenge)

      @challenge.verify_status == 'valid'
    end

    def store_challenge_in_filesystem(file_content)
      full_challenge_dir = File.join(Rails.root, CONFIG[:challenge_dir_name])
      Dir.mkdir(full_challenge_dir) unless File.directory?(full_challenge_dir)
      File.open(File.join(full_challenge_dir, 'challenge'), 'w') { |file| file.write(file_content) }
    end

    def store_challenge_in_db(file_content)
      ch = LetsencryptPlugin::Challenge.first
      ch = LetsencryptPlugin::Challenge.new if ch.nil?
      ch.update(response: file_content)
    end

    def store_challenge(challenge)
      Rails.logger.info('Storing challenge information...')
      if CONFIG[:challenge_dir_name].empty? # store in DB
        store_challenge_in_db(challenge.file_content)
      else # store in filesystem
        store_challenge_in_filesystem(challenge.file_content)
      end
      sleep(2)
    end

    def wait_for_status(challenge)
      Rails.logger.info('Waiting for challenge status...')
      counter = 0
      while challenge.verify_status == 'pending' && counter < 10
        sleep(1)
        counter += 1
      end
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

      return Rails.logger.error('Challenge verification failed! ' \
        "Error: #{challenge.error['type']}: #{challenge.error['detail']}") unless challenge_verification

      # We can now request a certificate
      Rails.logger.info('Creating CSR...')
      certificate = client.new_certificate(Acme::Client::CertificateRequest.new(names: [CONFIG[:domain]]))
      save_certificate(certificate)

      Rails.logger.info('Certificate has been generated.')
    end
  end
end
