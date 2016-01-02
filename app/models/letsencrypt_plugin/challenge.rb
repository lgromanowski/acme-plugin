module LetsencryptPlugin
  if defined?(ActiveRecord::Base) == 'constant' && ActiveRecord::Base.class == Class 
    class Challenge < ActiveRecord::Base
    end
  end
end
