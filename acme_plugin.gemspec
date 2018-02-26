require 'English'
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'acme_plugin/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'acme_plugin'
  s.version     = AcmePlugin::VERSION
  s.authors     = ['Lukasz Gromanowski']
  s.email       = ['lgromanowski@gmail.com']
  s.homepage    = 'https://github.com/lgromanowski/acme-plugin'
  s.summary     = 'ACME protocol plugin for Ruby on Rails applications'
  s.description = 'acme-plugin is a Ruby on Rails helper for ACME protocol services, ie. Let\'s Encrypt' \
                  'for retrieving SSL certificates (without using sudo, like original letsencrypt ' \
                  'client does). It uses acme-client gem for communication with ACME protocol server. '
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.required_ruby_version = '>=2.1.0'

  s.add_dependency 'acme-client', '~>0.6.2'
  s.add_dependency 'rails', '>=4.2'

  s.add_development_dependency 'codeclimate-test-reporter', '~>1.0.8'
  s.add_development_dependency 'minitest', '~>5.11.3'
  s.add_development_dependency 'minitest-rails', '~>3.0.0'
  s.add_development_dependency 'minitest-reporters', '~>1.1.19'
  s.add_development_dependency 'rubocop', '~>0.52.1'
  s.add_development_dependency 'simplecov', '~>0.13'
  s.add_development_dependency 'sqlite3', '~>1.3.13'
  s.add_development_dependency 'webmock', '~>3.3.0'
end
