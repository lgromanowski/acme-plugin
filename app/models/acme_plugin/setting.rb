module AcmePlugin
  if AcmePlugin.config.challenge_dir_name.blank? && defined?(ActiveRecord::Base) == 'constant' && ActiveRecord::Base.class == Class
    class Setting < ActiveRecord::Base
    end
  else
    class Setting
      attr_accessor :private_key
    end
  end
end
