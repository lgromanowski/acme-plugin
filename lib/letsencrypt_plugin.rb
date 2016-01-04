require 'letsencrypt_plugin/engine'
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

    def create_csr
      Rails.logger.info('Creating CSR...')
      Acme::Client::CertificateRequest.new(names: [CONFIG[:domain]])
    end

    def display_certificates(certificate)
      Rails.logger.info("====== #{CONFIG[:domain]}-cert.pem ======")
      puts certificate.to_pem

      Rails.logger.info("====== #{CONFIG[:domain]}-key.pem ======")
      puts certificate.request.private_key.to_pem

      Rails.logger.info("====== #{CONFIG[:domain]}-chain.pem ======")
      puts certificate.chain_to_pem

      Rails.logger.info("====== #{CONFIG[:domain]}-fullchain.pem ======")
      puts certificate.fullchain_to_pem
    end

    def save_on_heroku(certificate)
      Rails.logger.info('You are running this script on Heroku, please copy-paste certificates to your local machine')
      Rails.logger.info('and then follow https://devcenter.heroku.com/articles/ssl-endpoint guide:')

      display_certificates(certificate)
    end

    def save_on_filesystem(certificate, output_dir)
      Rails.logger.info('Saving certificates and key...')
      File.write(File.join(output_dir, "#{CONFIG[:domain]}-cert.pem"), certificate.to_pem)
      File.write(File.join(output_dir, "#{CONFIG[:domain]}-key.pem"), certificate.request.private_key.to_pem)
      File.write(File.join(output_dir, "#{CONFIG[:domain]}-chain.pem"), certificate.chain_to_pem)
      File.write(File.join(output_dir, "#{CONFIG[:domain]}-fullchain.pem"), certificate.fullchain_to_pem)
    end

    # Save the certificate and key
    def save_certificate(certificate)
      unless certificate.nil?
        return save_on_heroku(certificate) unless ENV['DYNO'].nil?

        output_dir = File.join(Rails.root, CONFIG[:output_cert_dir])

        if File.directory?(output_dir)
          save_on_filesystem(certificate, output_dir)
        else
          Rails.logger.error("Output directory: '#{output_dir}' does not exist!")
        end
      end
    end

    def generate_certificate
      register
      authorize

      handle_challenge

      if challenge_verification
        # We can now request a certificate
        certificate = client.new_certificate(create_csr)
        save_certificate(certificate)

        Rails.logger.info('Certificate has been generated.')
      else
        Rails.logger.error("Challenge verification failed! Error: #{challenge.error['type']}: #{challenge.error['detail']}")
      end
    end
  end
end
