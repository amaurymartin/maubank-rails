# frozen_string_literal: true

class Category < ApplicationRecord
  include Keyable

  belongs_to :user

  has_many :budgets, dependent: :destroy
  has_many :payments, dependent: :nullify

  validates :key, presence: true, uniqueness: true
  validates :description,
            presence: true,
            uniqueness: { scope: :user, case_sensitive: false }

  def to_param
    key
  end

  def budget_for(date)
    budgets.for(date).first
  end
end
