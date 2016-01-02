module LetsencryptPlugin
  class ApplicationController < ActionController::Base
    before_action :get_challenge_response, only: [:index]
    before_action :validate_length, only: [:index]
    
    def index
      # There is only one item in DB with challenge response from our task
      # we will use it to render plain text response
      render plain: @response.response, status: :ok
    end
    
    private
      def validate_length
        # Challenge request should have at least 128bit
        challenge_failed('Challenge failed - Request has invalid length!') if params[:challenge].nil? || params[:challenge].length < 16 || params[:challenge].length > 256
      end

      def get_challenge_response
        if (CONFIG[:challenge_dir_name])
          full_challenge_dir = File.join(File.join(Rails.root, CONFIG[:challenge_dir_name], 'challenge');
          @response = { :response => IO.read(full_challenge_dir) }
        else
          @response = Challenge.first
        end
        challenge_failed('Challenge failed - Can not get response from database!') if @response.nil?
      end

      def challenge_failed(msg)
        Rails.logger.error(msg)
        render plain: msg, status: :bad_request
      end
  end
end
