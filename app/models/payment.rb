# frozen_string_literal: true

class Payment < ApplicationRecord
  include Keyable

  attr_readonly :key, :created_at

  belongs_to :category, optional: true
  belongs_to :wallet

  validates :key, presence: true, uniqueness: true
  validates :effective_date, presence: true
  validates :amount, numericality: {
    greater_than: -1_000_000_000.00,
    other_than: 0.00,
    less_than: 1_000_000_000.00
  }
  validate :category_and_wallet_must_belong_to_same_user

  before_save :update_wallet_balance, if: -> { new_record? || amount_changed? }

  delegate :user, to: :wallet

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
