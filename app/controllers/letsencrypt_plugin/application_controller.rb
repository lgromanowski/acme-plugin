module LetsencryptPlugin
  class ApplicationController < ActionController::Base
    before_action :validate_length, only: [:index]
    
    def index
      # There is only one item in DB with challenge response from our task
      # we will use it to render plain text response
      @response = Challenge.first
      render plain: @response.response
    end
    
    private
      def validate_length
        # Challenge request should have at least 128bit
        challenge_failed if params[:challenge].nil? || params[:challenge].length < 16 || params[:challenge].length > 256
      end
      
      def challenge_failed
        raise ActionController::RoutingError.new('Challenge failed - invalid request.')
      end
  end
end
