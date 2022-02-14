# frozen_string_literal: true

json.wallet do
  json.extract! payment.wallet, :key, :description
end

if payment.category.present?
  json.category do
    json.extract! payment.category, :key, :description
  end
end

json.payment do
  json.partial! 'payments/payment', payment:
end

json.links do
  json.wallet wallet_path payment.wallet
  json.category category_path payment.category if payment.category.present?
  json.self payment_path payment
end
