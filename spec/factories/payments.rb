# frozen_string_literal: true

FactoryBot.define do
  factory :payment do
    wallet
    category { nil }
    effective_date { Date.current }
    amount { Faker::Number.between(from: -999_999_999.99, to: 999_999_999.99) }

    trait :categorized do
      category { create(:category, user: wallet.user) }
    end
  end
end
