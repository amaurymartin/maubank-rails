# frozen_string_literal: true

class Wallet < ApplicationRecord
  include Keyable

  attr_readonly :user_id, :key

  belongs_to :user

  has_many :payments, dependent: :delete_all

  validates :key, presence: true, uniqueness: true
  validates :description, presence: true,
                          uniqueness: { scope: :user, case_sensitive: false }
  validates :balance, numericality: {
    greater_than: -1_000_000_000.00, less_than: 1_000_000_000.00
  }

  def to_param
    key
  end
end
