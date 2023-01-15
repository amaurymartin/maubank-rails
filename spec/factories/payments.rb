# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id             :bigint           not null, primary key
#  amount         :decimal(11, 2)   not null
#  effective_date :date             not null
#  key            :uuid             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  category_id    :bigint
#  wallet_id      :bigint           not null
#
# Indexes
#
#  index_payments_on_category_id     (category_id)
#  index_payments_on_effective_date  (effective_date)
#  index_payments_on_key             (key) UNIQUE
#  index_payments_on_wallet_id       (wallet_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (wallet_id => wallets.id)
#
FactoryBot.define do
  factory :payment do
    wallet
    category { nil }
    effective_date { Date.current }
    amount { Faker::Number.between(from: -999_999_999.99, to: 999_999_999.99) }

    trait :categorized do
      category { create(:category, user: wallet.user) }
    end
  end
end
