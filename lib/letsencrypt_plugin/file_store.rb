require 'letsencrypt_plugin/challenge_store'

module LetsencryptPlugin
  class FileStore < ChallengeStore
    def store_content
      full_challenge_dir = File.join(Rails.root, CONFIG[:challenge_dir_name])
      Dir.mkdir(full_challenge_dir) unless File.directory?(full_challenge_dir)
      File.open(File.join(full_challenge_dir, 'challenge'), 'w') { |file| file.write(@content) }
    end
  end
end
