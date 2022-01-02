# frozen_string_literal: true

json.wallet do
  json.partial! wallet, as: :wallet
end

json.links do
  json.user user_path(wallet.user)
end
