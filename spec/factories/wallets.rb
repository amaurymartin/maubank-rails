# frozen_string_literal: true

FactoryBot.define do
  factory :wallet do
    user
    sequence(:description) { |n| "Wallet #{n}" }
    balance { Faker::Number.between(from: -999_999_999.99, to: 999_999_999.99) }

    trait :with_payment do
      after(:create) { |instance| create(:payment, wallet: instance) }
    end
  end
end
