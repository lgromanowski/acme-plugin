module LetsencryptPlugin
  class ChallengeStore
    def initialize(challenge_content)
      @content = challenge_content
    end

    def store
      display_info
      store_content
    end

    protected

    def display_info
      Rails.logger.info('Storing challenge information...')
    end
  end
end
