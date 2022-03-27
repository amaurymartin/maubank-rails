# frozen_string_literal: true

class Budget < ApplicationRecord
  include Keyable

  attr_readonly :category_id, :key

  belongs_to :category

  before_validation :set_starts_at_to_beginning_of_month
  before_validation :set_ends_at_to_end_of_month

  validates :key, presence: true, uniqueness: true
  validates :amount,
            numericality: { greater_than: 0.00, less_than: 1_000_000_000.00 }
  validates :starts_at, presence: true, uniqueness: { scope: :category }
  validates :ends_at, uniqueness: { scope: :category }, allow_nil: true

  validate :starts_at_cannot_be_in_the_past, unless: -> { starts_at.nil? }
  validate :ends_at_must_be_end_of_current_month_or_after
  validate :ends_at_must_be_after_starts_at

  before_save :update_endless_budgets, if: -> { ends_at.nil? }

  delegate :user, to: :category

  scope :endless_for, lambda { |category|
    where(category:).where(ends_at: nil).order(starts_at: :asc)
  }

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

  def set_starts_at_to_beginning_of_month
    return if starts_at.nil?

    self.starts_at = starts_at.beginning_of_month
  end

  def set_ends_at_to_end_of_month
    return if ends_at.nil?

    self.ends_at = ends_at.end_of_month
  end

  def starts_at_cannot_be_in_the_past
    return if starts_at >= Date.current.beginning_of_month

    errors.add(:starts_at, :invalid)
  end

  def ends_at_must_be_end_of_current_month_or_after
    return if ends_at.nil? || ends_at >= Date.current.end_of_month

    errors.add(:ends_at, :invalid)
  end

  def ends_at_must_be_after_starts_at
    return if starts_at.nil? || ends_at.nil?

    errors.add(:ends_at, :invalid) unless ends_at > starts_at
  end

  def update_endless_budgets
    Budget.endless_for(category).each do |endless_budget|
      new_ends_at =
        if endless_budget.starts_at > starts_at
          endless_budget.starts_at.end_of_month
        else
          starts_at - 1.day
        end

      endless_budget.update(ends_at: new_ends_at)
    end
  end
end
