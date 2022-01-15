# frozen_string_literal: true

class UsersController < ApplicationController
  skip_before_action :authenticate, only: :create
  before_action :set_user, except: :create
  before_action :check_ownership, except: :create

  def create
    @user = User.new(user_params)

    if @user.save
      render :show, locals: { user: @user }, status: :created
    else
      render :errors, status: :unprocessable_entity
    end
  end

  def show
    render :show, locals: { user: @user }, status: :ok
  end

  def update
    if @user.update(user_params)
      render :show, locals: { user: @user }, status: :ok
    else
      render :errors, status: :unprocessable_entity
    end
  end

  def destroy
    # FIXME: this should return :accepted and perform async
    if @user.destroy
      head :no_content
    else
      render :errors, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(
      %i[
        full_name nickname username email password password_confirmation
        documentation date_of_birth
      ]
    )
  end

  def set_user
    @user = User.find_by!(key: params[:key])
  end

  # FIXME: perhaps routes should be '/me' for example, without url key param
  def check_ownership
    # for other resources, ownership means current_user.resource.find_by!
    # this may result in a not found, then the same pattern is followed here
    record_not_found unless current_user == @user
  end
end
