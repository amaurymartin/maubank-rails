# frozen_string_literal: true

class Goal < ApplicationRecord
  include Keyable

  attr_readonly :user_id, :key, :created_at

  belongs_to :user

  validates :key, presence: true, uniqueness: true
  validates :description, presence: true,
                          uniqueness: { scope: :user, case_sensitive: false }
  validates :amount,
            numericality: { greater_than: 0.00, less_than: 1_000_000_000.00 }
  validates :starts_at, presence: true
  validates :ends_at, comparison: { greater_than: :starts_at },
                      unless: -> { starts_at.nil? }

  def to_param
    key
  end
end
