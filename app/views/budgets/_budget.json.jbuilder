# frozen_string_literal: true

json.user_key budget.user.key
json.category_key budget.category.key
json.extract!(
  budget,
  :key, :amount, :starts_at, :ends_at, :created_at, :updated_at
)
