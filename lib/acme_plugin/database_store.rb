require 'acme_plugin/challenge_store'

module AcmePlugin
  class DatabaseStore < ChallengeStore
    def store_content
      ch = AcmePlugin::Challenge.first
      ch = AcmePlugin::Challenge.new if ch.nil?
      ch.update(response: @content)
    end
  end
end
