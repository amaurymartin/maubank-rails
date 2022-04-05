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
  validates :ends_at, presence: true
  validate :ends_at_must_be_after_starts_at

  def to_param
    key
  end

  private

  def ends_at_must_be_after_starts_at
    return if starts_at.nil? || ends_at.nil? || ends_at > starts_at

    errors.add(:ends_at, :invalid)
  end
end
