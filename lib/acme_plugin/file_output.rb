require 'acme_plugin/certificate_output'

module AcmePlugin
  class FileOutput < CertificateOutput
    def initialize(domain, cert, out_dir)
      super(domain, cert)
      @output_dir = out_dir
    end

    def output_cert(cert_type, cert_content)
      File.write(File.join(@output_dir, "#{@domain}-#{cert_type}"), cert_content)
    end

    def display_info
      Rails.logger.info('Saving certificates and key...')
    end
  end
end
