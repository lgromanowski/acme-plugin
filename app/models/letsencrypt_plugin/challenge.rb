module LetsencryptPlugin
  # if the project doesn't use ActiveRecord, we assume the challenge will
  # be stored in the filesystem
  if defined?(ActiveRecord::Base) == 'constant' && ActiveRecord::Base.class == Class 
    class Challenge < ActiveRecord::Base
    end
  end
end
