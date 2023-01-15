# frozen_string_literal: true

# == Schema Information
#
# Table name: goals
#
#  id          :bigint           not null, primary key
#  amount      :decimal(11, 2)   not null
#  description :text             not null
#  ends_at     :date             not null
#  key         :uuid             not null
#  starts_at   :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_goals_on_key                      (key) UNIQUE
#  index_goals_on_user_id                  (user_id)
#  index_goals_on_user_id_and_description  (user_id,description) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :goal do
    user
    sequence(:description) { |n| "Goal #{n}" }
    amount { Faker::Number.between(from: 0.01, to: 999_999_999.99) }
    starts_at { Date.current.beginning_of_year }
    ends_at { Date.current.end_of_year }
  end
end
