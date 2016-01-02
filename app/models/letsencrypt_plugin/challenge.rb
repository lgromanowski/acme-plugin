module LetsencryptPlugin
  # if the project doesn't use ActiveRecord, we assume the challenge will
  # be stored in the filesystem
  if defined?(ActiveRecord::Base) == 'constant' && ActiveRecord::Base.class == Class 
    class Challenge < ActiveRecord::Base
    end
  else
    class Challenge
      attr_accessor :response

      def initialize
        full_challenge_dir = File.join(Rails.root, CONFIG[:challenge_dir_name], 'challenge')
        @response = IO.read(full_challenge_dir)
      end
    end
  end
end
