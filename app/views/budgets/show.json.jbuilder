# frozen_string_literal: true

json.budget do
  json.partial! budget, as: :budget
end

json.links do
  json.user user_path(budget.user)
  json.category category_path(budget.category)
end
