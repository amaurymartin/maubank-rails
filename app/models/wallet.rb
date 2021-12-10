# frozen_string_literal: true

class Wallet < ApplicationRecord
  include Keyable

  belongs_to :user

  has_many :payments, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :description, presence: true,
                          uniqueness: { scope: :user, case_sensitive: false }
end
