# frozen_string_literal: true

json.payments do
  json.array! @payments do |payment|
    # rubocop:disable Style/HashSyntax
    json.partial! 'payments/payment', payment: payment
    # rubocop:enable Style/HashSyntax

    json.wallet do
      json.extract! payment.wallet, :description
    end

    if payment.category.present?
      json.category do
        json.extract! payment.category, :description
      end
    end

    json.links do
      json.wallet wallet_path payment.wallet
      json.category category_path payment.category if payment.category.present?
      json.self payment_path payment
    end
  end
end
