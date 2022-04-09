# frozen_string_literal: true

json.categories do
  json.array! categories do |category|
    json.partial! category, as: :category

    if category.current_budget.present?
      json.budget do
        json.extract! category.current_budget,
                      :key, :amount, :starts_at, :ends_at
      end
    end

    json.links do
      json.self category_path(category)
      if category.current_budget.present?
        json.budget budget_path(category.current_budget)
      end
    end
  end
end
