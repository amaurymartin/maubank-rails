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

  before_save :update_wallet_balance, if: -> { new_record? || amount_changed? }

  delegate :user, to: :wallet

  def to_param
    key
  end

  private

  def update_wallet_balance
    wallet.update_balance(amount)
  end
end
