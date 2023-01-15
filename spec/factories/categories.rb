# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id          :bigint           not null, primary key
#  description :text             not null
#  key         :uuid             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_categories_on_key                      (key) UNIQUE
#  index_categories_on_user_id                  (user_id)
#  index_categories_on_user_id_and_description  (user_id,description) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :category do
    user
    sequence(:description) { |n| "Category #{n}" }

    trait :with_budget do
      after(:create) { |instance| create(:budget, category: instance) }
    end
  end
end
