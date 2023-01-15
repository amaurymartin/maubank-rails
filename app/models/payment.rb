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
class Payment < ApplicationRecord
  include Keyable

  attr_readonly :key, :created_at

  belongs_to :category, optional: true
  belongs_to :wallet

  delegate :user, to: :wallet

  validates :key, presence: true, uniqueness: true
  validates :effective_date, presence: true
  validates :amount, numericality: {
    greater_than: -1_000_000_000.00,
    other_than: 0.00,
    less_than: 1_000_000_000.00
  }
  validate :category_and_wallet_must_belong_to_same_user

  before_save :update_wallet_balance, if: -> { new_record? || amount_changed? }
  after_destroy :update_wallet_balance

  def to_param
    key
  end

  private

  def category_and_wallet_must_belong_to_same_user
    return if category.nil?

    errors.add(:category, :invalid) unless category.user == wallet.user
  end

  def update_wallet_balance
    wallet.update_balance(amount)
  end
end
