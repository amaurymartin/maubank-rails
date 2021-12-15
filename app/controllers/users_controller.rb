# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, except: :create

  def create
    @user = User.new(user_params)

    if @user.save
      render :show, status: :created
    else
      render :errors, status: :unprocessable_entity
    end
  end

  def show
    render :show, status: :ok
  end

  def update
    if @user.update(user_params)
      render :show, status: :ok
    else
      render :errors, status: :unprocessable_entity
    end
  end

  def destroy
    # FIXME: this should return :accepted and perform async
    head :no_content if @user.destroy
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
end
