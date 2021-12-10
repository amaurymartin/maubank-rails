# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    user
    description { 'First category' }

    trait :with_budget do
      after(:create) { |instance| create(:budget, category: instance) }
    end

    trait :with_payment do
      after(:create) { |instance| create(:payment, category: instance) }
    end
  end
end
