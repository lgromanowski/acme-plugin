require 'English'
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'letsencrypt_plugin/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'letsencrypt_plugin'
  s.version     = LetsencryptPlugin::VERSION
  s.authors     = ['Lukasz Gromanowski']
  s.email       = ['lgromanowski@gmail.com']
  s.homepage    = 'https://github.com/lgromanowski/letsencrypt-plugin'
  s.summary     = 'Let\'s encrypt plugin for Ruby on Rails applications'
  s.description = 'letsencrypt-plugin is a Ruby on Rails helper for Let\'s Encrypt service ' \
                  'for retrieving SSL certificates (without using sudo, like original letsencrypt ' \
                  'client does). It uses acme-client gem for communication with Let\'s Encrypt server. '
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.required_ruby_version = '>= 2.1.0'

  s.add_dependency 'rails', '>= 4.2', '< 5.1'
  s.add_dependency 'acme-client', '~> 0.3.0'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-rails'
  s.add_development_dependency 'minitest-reporters'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'codeclimate-test-reporter'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'byebug'
end
