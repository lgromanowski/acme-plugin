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

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new
Minitest::Reporters.use!

CodeClimate::TestReporter.start
SimpleCov.start

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path('../fixtures', __FILE__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.fixtures :all
end
