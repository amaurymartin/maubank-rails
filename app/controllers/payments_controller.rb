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
    @payment.category = @new_category unless @new_category == @payment.category

    if @payment.update(payment_params)
      render :show, locals: { payment: @payment }, status: :ok
    else
      render :errors, status: :unprocessable_content
    end
  end

  def destroy
    if @payment.destroy
      head :no_content
    else
      render :errors, status: :unprocessable_content
    end
  end

  private

  def set_payment
    @payment = current_user.payments.find_by!(key: params[:key])
  end

  def set_new_category
    return unless category_params && category_params[:key]

    @new_category = current_user.categories.find_by!(key: category_params[:key])
  end

  def category_params
    params.require(:payment).permit(category: [:key])[:category]
  end

  def payment_params
    params.require(:payment)
          .permit(:effective_date, :amount)
          .merge(category: @new_category)
  end
end
