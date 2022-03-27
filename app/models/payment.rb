# frozen_string_literal: true

class Payment < ApplicationRecord
  include Keyable

  attr_readonly :key

  belongs_to :category, optional: true
  belongs_to :wallet

  validates :key, presence: true, uniqueness: true
  validates :effective_date, presence: true
  validates :amount, numericality: {
    greater_than: -1_000_000_000.00,
    other_than: 0.00,
    less_than: 1_000_000_000.00
  }

  delegate :user, to: :wallet

  def to_param
    key
  end
end
