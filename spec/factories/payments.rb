# frozen_string_literal: true

FactoryBot.define do
  factory :payment do
    category
    wallet
    effective_date { Date.current }
    amount { Faker::Number.between(from: 0.01, to: 999_999_999.99) }

    trait :uncategorized do
      category { nil }
    end
  end
end
