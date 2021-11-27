# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    user
    description { 'First category' }
  end
end
