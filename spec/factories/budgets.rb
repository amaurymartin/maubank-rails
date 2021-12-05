# frozen_string_literal: true

FactoryBot.define do
  factory :budget do
    category
    amount { Faker::Number.between(from: 0.01, to: 999_999_999.99) }
    starts_at { Date.current.beginning_of_month }
    ends_at { starts_at&.end_of_month }
  end
end
