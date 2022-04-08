# frozen_string_literal: true

json.user do
  json.partial! user, as: :user

  json.links do
    json.self user_path(user)
    json.categories categories_path
    json.goals goals_path
    json.payments payments_path
    json.wallets wallets_path
  end
end
