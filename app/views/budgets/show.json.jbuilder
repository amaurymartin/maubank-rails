# frozen_string_literal: true

json.user do
  json.extract! budget.user, :key
end

json.category do
  json.extract! budget.category, :key, :description
end

json.budget do
  json.partial! budget, as: :budget
end

json.links do
  json.user user_path budget.user
  json.category category_path budget.category
  json.self budget_path budget
end
