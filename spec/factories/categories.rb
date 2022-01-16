# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    user
    sequence(:description) { |n| "Category #{n}" }

    trait :with_budget do
      after(:create) { |instance| create(:budget, category: instance) }
    end

    trait :with_payment do
      after(:create) { |instance| create(:payment, category: instance) }
    end
  end
end
