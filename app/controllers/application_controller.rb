# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  before_action :authenticate

  def current_user
    @current_user ||= @access_token&.user
  end

  private

  def record_not_found
    head :not_found
  end

  def authenticate
    authenticate_with_http_token do |plain_access_token|
      @access_token ||= AccessToken.usable.find_by(
        token: Digest::SHA256.hexdigest(plain_access_token)
      )

      current_user
    end

    head :unauthorized if @current_user.nil?
  end
end
