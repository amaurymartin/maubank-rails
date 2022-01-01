# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authenticate, only: :create

  def create
    render :unauthorized, status: :unauthorized and return unless current_user

    @access_token = @current_user.access_tokens.build
    @plain_access_token = @access_token.send(:generated_token)

    if @access_token.save
      render :create, status: :created
    else
      render :errors, status: :unprocessable_entity
    end
  end

  private

  def current_user
    @current_user ||= authenticate
  end

  def authenticate
    user = User.find_by(email: session_params[:email])
    user&.authenticate(session_params[:password])
  end

  def session_params
    params.require(:session).permit(%i[email password])
  end
end
