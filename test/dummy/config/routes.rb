Rails.application.routes.draw do

  mount LetsencryptPlugin::Engine => "/letsencrypt_plugin"
end
