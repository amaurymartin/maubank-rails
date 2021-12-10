# frozen_string_literal: true

FactoryBot.define do
  factory :wallet do
    user
    description { 'First wallet' }

    trait :with_payment do
      after(:create) { |instance| create(:payment, wallet: instance) }
    end
  end
end
