require 'acme_plugin/challenge_store'

module AcmePlugin
  class FileStore < ChallengeStore
    def initialize(challenge_content, challenge_dir_name)
      super(challenge_content)
      @challenge_dir_name = challenge_dir_name
    end

    def store_content
      full_challenge_dir = File.join(Rails.root, @challenge_dir_name)
      Dir.mkdir(full_challenge_dir) unless File.directory?(full_challenge_dir)
      File.open(File.join(full_challenge_dir, 'challenge'), 'w') { |file| file.write(@content) }
    end
  end
end
