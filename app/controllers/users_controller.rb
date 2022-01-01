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

  def check_ownership
    # FIXME: hackers could use this response status to discover user's key
    # request limit is required to prevent this
    head :forbidden unless current_user == @user
  end
end
