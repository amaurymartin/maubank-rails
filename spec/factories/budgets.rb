# frozen_string_literal: true

# == Schema Information
#
# Table name: budgets
#
#  id          :bigint           not null, primary key
#  amount      :decimal(11, 2)   not null
#  ends_at     :date
#  key         :uuid             not null
#  starts_at   :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category_id :bigint           not null
#
# Indexes
#
#  index_budgets_on_category_id                (category_id)
#  index_budgets_on_category_id_and_ends_at    (category_id,ends_at) UNIQUE
#  index_budgets_on_category_id_and_starts_at  (category_id,starts_at) UNIQUE
#  index_budgets_on_key                        (key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#
FactoryBot.define do
  factory :budget do
    category
    amount { Faker::Number.between(from: 0.01, to: 999_999_999.99) }
    starts_at { Date.current.beginning_of_month }
    ends_at { starts_at&.end_of_month }
  end
end
