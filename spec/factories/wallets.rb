# frozen_string_literal: true

# == Schema Information
#
# Table name: wallets
#
#  id          :bigint           not null, primary key
#  balance     :decimal(11, 2)   not null
#  description :text             not null
#  key         :uuid             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_wallets_on_key                      (key) UNIQUE
#  index_wallets_on_user_id                  (user_id)
#  index_wallets_on_user_id_and_description  (user_id,description) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :wallet do
    user
    sequence(:description) { |n| "Wallet #{n}" }
    balance { Faker::Number.between(from: -999_999_999.99, to: 999_999_999.99) }

    trait :with_payment do
      after(:create) { |instance| create(:payment, wallet: instance) }
    end
  end
end
