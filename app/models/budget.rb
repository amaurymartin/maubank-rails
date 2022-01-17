# frozen_string_literal: true

class Budget < ApplicationRecord
  include Keyable

  belongs_to :category

  validates :key, presence: true, uniqueness: true
  validates :amount,
            numericality: { greater_than: 0.00, less_than: 1_000_000_000.00 }
  validates :starts_at, presence: true, uniqueness: { scope: :category }
  validates :ends_at, uniqueness: { scope: :category }

  validate :starts_at_cannot_be_in_the_past, if: -> { starts_at.present? }
  validate :ends_at_cannot_be_before_starts_at

  before_validation :set_starts_at_with_beginning_of_month
  before_validation :set_ends_at_with_end_of_month
  before_validation :posdate_current_budget, if: -> { ends_at.nil? }

  delegate :user, to: :category

  scope :for, lambda { |date|
    where('? BETWEEN starts_at AND ends_at', date)
      .or(where('? >= starts_at', date).where(ends_at: nil))
      .order(ends_at: :asc)
      .limit(1)
  }

  def to_param
    key
  end

  private

  def starts_at_cannot_be_in_the_past
    return if starts_at >= Date.current.beginning_of_month

    errors.add(:starts_at, :invalid)
  end

  def ends_at_cannot_be_before_starts_at
    return if starts_at.nil? || ends_at.nil?

    errors.add(:ends_at, :invalid) unless ends_at > starts_at
  end

  def set_starts_at_with_beginning_of_month
    return if starts_at.nil?

    self.starts_at = starts_at.beginning_of_month
  end

  def set_ends_at_with_end_of_month
    return if ends_at.nil?

    self.ends_at = ends_at.end_of_month
  end

  def posdate_current_budget
    current_budget = category.budgets.reload.find { |b| b.ends_at.nil? }

    return if current_budget.nil?

    new_ends_at =
      if current_budget.starts_at > starts_at
        current_budget.starts_at.end_of_month
      else
        starts_at - 1.day
      end

    current_budget.update(ends_at: new_ends_at)
  end
end
