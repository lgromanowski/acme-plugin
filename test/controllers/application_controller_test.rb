require 'test_helper'

module LetsencryptPlugin
  class ApplicationControllerTest < ActionController::TestCase
    setup do
      @routes = LetsencryptPlugin::Engine.routes
    end

    test 'if challenge request is invalid when is smaller than 128 bits' do
      get :index, challenge: 'dG9rZW4='
      assert_response :bad_request
      assert_match('Challenge failed - Request has invalid length!', response.body)
    end

    test 'if challenge request is invalid if it is larger than 256 bytes' do
      get :index, challenge: 'a' * 257
      assert_response :bad_request
      assert_match('Challenge failed - Request has invalid length!', response.body)
    end

    test 'if challenge is valid' do
      get :index, challenge: 'rpzxDjD-8xrr5I1G_JBTEToVMYgjNjfSs-XZ62tRtgs'
      assert_response :ok
    end
  end
end
