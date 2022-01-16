# frozen_string_literal: true

json.category do
  json.partial! category, as: :category
end

json.links do
  json.user user_path(category.user)
end
