# frozen_string_literal: true

FactoryBot.define do
  factory :payment do
    wallet
    category { wallet ? association(:category, user: wallet.user) : nil }
    effective_date { Date.current }
    amount { Faker::Number.between(from: -999_999_999.99, to: 999_999_999.99) }

    trait :uncategorized do
      category { nil }
    end
  end
end
