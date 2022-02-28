# frozen_string_literal: true

class WalletsController < ApplicationController
  before_action :set_wallet, except: %i[create index]

  def create
    @wallet = current_user.wallets.new(wallet_params)

    if @wallet.save
      render :show, locals: { wallet: @wallet }, status: :created
    else
      render :errors, status: :unprocessable_entity
    end
  end

  def index
    @wallets = current_user.wallets

    render :index, locals: { wallets: @wallets }, status: :ok
  end

  def update
    if @wallet.update(wallet_params)
      render :show, locals: { wallet: @wallet }, status: :ok
    else
      render :errors, status: :unprocessable_entity
    end
  end

  def destroy
    # FIXME: this should return :accepted and perform async
    if @wallet.destroy
      head :no_content
    else
      render :errors, status: :unprocessable_entity
    end
  end

  private

  def wallet_params
    params.require(:wallet).permit(
      action_name == 'create' ? %i[description balance] : :description
    )
  end

  def set_wallet
    @wallet = current_user.wallets.find_by!(key: params[:key])
  end
end
