# frozen_string_literal: true

class PaymentsController < ApplicationController
  before_action :set_payment, except: :index
  before_action :set_new_category, only: :update

  def index
    @payments = current_user.payments.includes(%i[wallet category])

    render :index, locals: { payments: @payments }, status: :ok
  end

  def show
    render :show, locals: { payment: @payment }, status: :ok
  end

  def update
    @payment.category = @new_category if @payment.category != @new_category

    if @payment.update(payment_params)
      render :show, locals: { payment: @payment }, status: :ok
    else
      render :errors, status: :unprocessable_entity
    end
  end

  def destroy
    if @payment.destroy
      head :no_content
    else
      render :errors, status: :unprocessable_entity
    end
  end

  private

  def set_payment
    @payment = current_user.payments.find_by!(key: params[:key])
  end

  def set_new_category
    return unless update_params[:category] && update_params[:category][:key]

    @new_category = current_user.categories.find_by!(
      key: update_params[:category][:key]
    )
  end

  def update_params
    params.require(:payment).permit(:effective_date, :amount, category: [:key])
  end

  def payment_params
    update_params.reject { |k| k == 'category' }
  end
end
