# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    full_name { Faker::Name.name }
    nickname { Faker::TvShows::GameOfThrones.dragon }
    username { Faker::Internet.username(specifier: full_name) }
    email { Faker::Internet.safe_email(name: full_name) }
    password { Faker::Internet.password(min_length: 8) }
    password_confirmation { password }
    documentation { Faker::IDNumber.brazilian_citizen_number }
    date_of_birth { Faker::Date.backward(days: 1) }

    trait :confirmed do
      after(:create, &:confirm!)
    end

    trait :with_goal do
      after(:create) { |instance| create(:goal, user: instance) }
    end

    trait :with_wallet do
      after(:create) { |instance| create(:wallet, user: instance) }
    end
  end
end
