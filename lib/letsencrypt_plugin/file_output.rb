module LetsencryptPlugin
  class FileOutput < Output
    def initialize(cert, out_dir)
      super(cert)
      @output_dir = out_dir
    end

    protected

    def output_cert(cert_type, cert_content)
      File.write(File.join(@output_dir, "#{CONFIG[:domain]}-#{cert_type}"), cert_content)
    end

    def display_info
      Rails.logger.info('Saving certificates and key...')
    end
  end
end
