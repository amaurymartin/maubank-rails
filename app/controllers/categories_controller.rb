# frozen_string_literal: true

class CategoriesController < ApplicationController
  before_action :set_category, except: %i[create index]

  def create
    @category = current_user.categories.new(category_params)

    if @category.save
      render :show, locals: { category: @category }, status: :created
    else
      render :errors, status: :unprocessable_entity
    end
  end

  def index
    @categories = current_user.categories

    render :index, locals: { categories: @categories }, status: :ok
  end

  def show
    render :show, locals: { category: @category }, status: :ok
  end

  def update
    if @category.update(category_params)
      render :show, locals: { category: @category }, status: :ok
    else
      render :errors, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.destroy
      head :no_content
    else
      render :errors, status: :unprocessable_entity
    end
  end

  private

  def category_params
    params.require(:category).permit(:description)
  end

  def set_category
    @category = current_user.categories.find_by!(key: params[:key])
  end
end
