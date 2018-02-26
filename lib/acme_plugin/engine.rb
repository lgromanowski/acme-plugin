module AcmePlugin
  class Engine < ::Rails::Engine
    isolate_namespace AcmePlugin
  end
end
