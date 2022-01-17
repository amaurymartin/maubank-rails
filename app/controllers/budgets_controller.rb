# frozen_string_literal: true

class BudgetsController < ApplicationController
  before_action :set_category, only: :create
  before_action :set_budget, except: :create

  def create
    @budget = @category.budgets.new(budget_params)

    if @budget.save
      render :show, locals: { budget: @budget }, status: :created
    else
      render :errors, status: :unprocessable_entity
    end
  end

  def show
    render :show, locals: { budget: @budget }, status: :ok
  end

  def update
    if @budget.update(budget_params)
      render :show, locals: { budget: @budget }, status: :ok
    else
      render :errors, status: :unprocessable_entity
    end
  end

  def destroy
    if @budget.destroy
      head :no_content
    else
      render :errors, status: :unprocessable_entity
    end
  end

  private

  def budget_params
    params.require(:budget).permit(:amount, :starts_at, :ends_at)
  end

  def set_category
    @category = current_user.categories.find_by!(key: params[:category_key])
  end

  def set_budget
    @budget = current_user.budgets.find_by!(key: params[:key])
  end
end
