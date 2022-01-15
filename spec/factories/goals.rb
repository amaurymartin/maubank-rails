# frozen_string_literal: true

FactoryBot.define do
  factory :goal do
    user
    sequence(:description) { |n| "Goal #{n}" }
    amount { Faker::Number.between(from: 0.01, to: 999_999_999.99) }
    starts_at { Time.zone.today.beginning_of_year }
    ends_at { Time.zone.today.end_of_year }
  end
end
