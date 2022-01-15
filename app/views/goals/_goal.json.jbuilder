# frozen_string_literal: true

json.user_key goal.user.key
json.extract!(
  goal,
  :key, :description, :amount, :starts_at, :ends_at, :created_at, :updated_at
)
