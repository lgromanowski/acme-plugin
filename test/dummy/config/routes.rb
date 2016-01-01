Rails.application.routes.draw do
  mount LetsencryptPlugin::Engine => '/'
end
