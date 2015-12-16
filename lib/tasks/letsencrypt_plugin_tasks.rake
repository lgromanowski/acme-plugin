require 'openssl'
require 'acme-client'

#Sets up logging - should only be called from other rake tasks
task setup_logger: :environment do
  logger           = Logger.new(STDOUT)
  logger.level     = Logger::INFO
  Rails.logger     = logger
end

desc "Generates SSL certificate using Let's Encrypt service"
task :letsencrypt_plugin => :setup_logger do
  def generate_certificate()
    client ||= Acme::Client.new(private_key: load_private_key, endpoint: CONFIG[:endpoint])
    Rails.logger.info("Trying to register at Let's Encrypt service...")
    begin
      registration = client.register(contact: 'mailto:#{CONFIG[:email]}')
      registration.agree_terms
      Rails.logger.info("Registration succeed.")
    rescue
      Rails.logger.info("Already registered.")
    end

    Rails.logger.info("Sending authorization request...")
    authorization = client.authorize(domain: CONFIG[:domain])
    challenge = authorization.http01
    
    store_challenge(challenge)

    challenge.request_verification # => true
    
    wait_for_status(challenge)
    
    if challenge.verify_status == 'valid'
      certificate_private_key = OpenSSL::PKey::RSA.new(2048)
      csr = create_csr(certificate_private_key)
      # We can now request a certificate
      certificate = client.new_certificate(csr) # => #<Acme::Certificate ....>
      save_certificate(certificate, certificate_private_key)

      Rails.logger.info("Certificate has been generated.")
    else
      Rails.logger.error("Challenge verification failed!")
    end
  end
  
  def load_private_key
    Rails.logger.info("Loading private key...")
    OpenSSL::PKey::RSA.new(File.read(File.join(Rails.root, CONFIG[:private_key])))
  end
  
  def store_challenge(challenge)
    Rails.logger.info("Storing challenge information...")
    ch = LetsencryptPlugin::Challenge.first
    if ch.nil?
      ch = LetsencryptPlugin::Challenge.new
      ch.save!(:response => challenge.file_content)
    else
      ch.update(:response => challenge.file_content)
    end
    sleep(1)
  end

  def wait_for_status(challenge)
    Rails.logger.info("Waiting for challenge status...")
    counter = 0
    while challenge.verify_status == 'pending' && counter < 10
      sleep(1)
      counter += 1
    end
  end

  def create_csr(certificate_private_key)
    Rails.logger.info("Creating CSR...")
    Acme::CertificateRequest.new(names: CONFIG[:domain])
  end
  
  # Save the certificate and key
  def save_certificate(certificate, certificate_private_key)
    if !certificate.nil?
      Rails.logger.info("Saving certificates and key...")
      File.write(File.join(CONFIG[:output_cert_dir], "#{CONFIG[:domain]}-cert.pem"), certificate.to_pem)
      File.write(File.join(CONFIG[:output_cert_dir], "#{CONFIG[:domain]}-key.pem"), certificate_private_key.to_pem)
      File.write(File.join(CONFIG[:output_cert_dir], "#{CONFIG[:domain]}-chain.pem"), certificate.chain_to_pem)
      File.write(File.join(CONFIG[:output_cert_dir], "#{CONFIG[:domain]}-fullchain.pem"), certificate.fullchain_to_pem)
    end
  end
  
  generate_certificate
end
