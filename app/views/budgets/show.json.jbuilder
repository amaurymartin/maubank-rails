# frozen_string_literal: true

# frozen_string_literal: true

json.budget do
  json.partial! budget, as: :budget

  json.category do
    json.extract! budget.category, :key, :description
  end
end

json.links do
  json.self budget_path(budget)
  json.category category_path(budget.category)
end
