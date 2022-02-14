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
      return unless create_params[:category] && create_params[:category][:key]

      @category = current_user.categories.find_by!(
        key: create_params[:category][:key]
      )
    end

    def create_params
      params.require(:payment)
            .permit(:effective_date, :amount, category: [:key])
    end

    def payment_params
      return create_params.merge(category: @category) if @category.present?

      create_params.reject { |k| k == 'category' }
    end
  end
end
