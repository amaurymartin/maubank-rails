# frozen_string_literal: true

json.payments do
  json.array! @payments do |payment|
    json.partial!('payments/payment', payment:)

    json.wallet do
      json.extract! payment.wallet, :key, :description, :balance
    end

    if payment.category.present?
      json.category do
        json.extract! payment.category, :key, :description
      end
    end

    json.links do
      json.self payment_path(payment)
      json.wallet wallet_path(payment.wallet)
      json.category category_path(payment.category) if payment.category.present?
    end
  end
end
