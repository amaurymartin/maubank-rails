# frozen_string_literal: true

class Category < ApplicationRecord
  include Keyable

  belongs_to :user

  has_many :budgets, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :description,
            presence: true,
            uniqueness: { scope: :user, case_sensitive: false }
end
