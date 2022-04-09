# frozen_string_literal: true

json.wallets do
  json.array! wallets do |wallet|
    json.partial! wallet, as: :wallet

    json.links do
      json.self wallet_path(wallet)
      json.payments wallet_payments_path(wallet)
    end
  end
end
