require 'openssl'
require 'acme/client'

# Sets up logging - should only be called from other rake tasks
task setup_logger: :environment do
  logger           = Logger.new(STDOUT)
  logger.level     = Logger::INFO
  Rails.logger     = logger
end

desc "Generates SSL certificate using Let's Encrypt service"
task acme_plugin: :setup_logger do
  cert_generator = AcmePlugin::CertGenerator.new(AcmePlugin.config.to_h)
  cert_generator.generate_certificate
end
