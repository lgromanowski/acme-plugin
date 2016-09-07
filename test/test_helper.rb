# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require 'codeclimate-test-reporter'
require 'simplecov'
require 'byebug'

require File.expand_path('../../test/dummy/config/environment.rb', __FILE__)
require 'rails/test_help'
require 'minitest/rails'
require 'minitest/reporters'
require 'webmock/minitest'

#Minitest::Reporters.use!
CodeClimate::TestReporter.start
SimpleCov.start
