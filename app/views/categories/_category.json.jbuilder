# frozen_string_literal: true

json.user_key category.user.key
json.extract!(
  category,
  :key, :description, :created_at, :updated_at
)
