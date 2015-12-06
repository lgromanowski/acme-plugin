LetsencryptPlugin::Engine.routes.draw do
  get '.well-known/acme-challenge/:challenge' => 'application#index'
end
