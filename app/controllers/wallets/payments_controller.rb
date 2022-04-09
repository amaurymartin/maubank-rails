# frozen_string_literal: true

module Wallets
  class PaymentsController < ApplicationController
    before_action :set_wallet
    before_action :set_category, only: :create

    def create
      @payment = @wallet.payments.new(payment_params)

      if @payment.save
        render 'payments/show', locals: { payment: @payment }, status: :created
      else
        render 'payments/errors', status: :unprocessable_entity
      end
    end

    def index
      @payments = @wallet.payments.includes(:category)

      render 'payments/index', locals: { payments: @payments }, status: :ok
    end

    private

    def set_wallet
      @wallet = current_user.wallets.find_by!(key: params[:wallet_key])
    end

    def set_category
      return unless category_params && category_params[:key]

      @category = current_user.categories.find_by!(key: category_params[:key])
    end

    def category_params
      params.require(:payment).permit(category: [:key])[:category]
    end

    def payment_params
      params.require(:payment)
            .permit(:effective_date, :amount)
            .merge(category: @category)
    end
  end
end
