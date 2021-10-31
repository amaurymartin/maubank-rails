# frozen_string_literal: true

FactoryBot.define do
  factory :wallet do
    user
    description { 'First wallet' }
  end
end
