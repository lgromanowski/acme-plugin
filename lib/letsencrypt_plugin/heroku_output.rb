module LetsencryptPlugin
  class HerokuOutput < Output
    protected

    def output_cert(cert_type, cert_content)
      Rails.logger.info("====== #{CONFIG[:domain]}-#{cert_type} ======")
      puts cert_content
    end

    def display_info
      Rails.logger.info('You are running this script on Heroku, please copy-paste certificates to your local machine')
      Rails.logger.info('and then follow https://devcenter.heroku.com/articles/ssl-endpoint guide:')
    end
  end
end
