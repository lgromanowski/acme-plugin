module AcmePlugin
  class CertificateOutput
    def initialize(domain, cert)
      @certificate = cert
      @domain = domain
    end

    def output
      display_info

      output_cert('cert.pem', @certificate.to_pem)
      output_cert('key.pem', @certificate.request.private_key.to_pem)
      output_cert('chain.pem', @certificate.chain_to_pem)
      output_cert('fullchain.pem', @certificate.fullchain_to_pem)
    end
  end
end
