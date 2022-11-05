# frozen_string_literal: true

class GoalsController < ApplicationController
  before_action :set_goal, except: %i[create index]

  def index
    @goals = current_user.goals

    render :index, locals: { goals: @goals }, status: :ok
  end

  def show
    render :show, locals: { goal: @goal }, status: :ok
  end

  def create
    @goal = current_user.goals.new(goal_params)

    if @goal.save
      render :show, locals: { goal: @goal }, status: :created
    else
      render :errors, status: :unprocessable_entity
    end
  end

  def update
    if @goal.update(goal_params)
      render :show, locals: { goal: @goal }, status: :ok
    else
      render :errors, status: :unprocessable_entity
    end
  end

  def destroy
    if @goal.destroy
      head :no_content
    else
      render :errors, status: :unprocessable_entity
    end
  end

  private

  def goal_params
    params.require(:goal).permit(:description, :amount, :starts_at, :ends_at)
  end

  def set_goal
    @goal = current_user.goals.find_by!(key: params[:key])
  end
end
