# frozen_string_literal: true

FactoryBot.define do
  factory :access_token do
    user

    trait :revoked do
      after(:create, &:revoke!)
    end
  end
end
