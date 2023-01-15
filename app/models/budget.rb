# frozen_string_literal: true

# == Schema Information
#
# Table name: budgets
#
#  id          :bigint           not null, primary key
#  amount      :decimal(11, 2)   not null
#  ends_at     :date
#  key         :uuid             not null
#  starts_at   :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category_id :bigint           not null
#
# Indexes
#
#  index_budgets_on_category_id                (category_id)
#  index_budgets_on_category_id_and_ends_at    (category_id,ends_at) UNIQUE
#  index_budgets_on_category_id_and_starts_at  (category_id,starts_at) UNIQUE
#  index_budgets_on_key                        (key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#
class Budget < ApplicationRecord
  include Keyable

  attr_readonly :category_id, :key, :created_at

  belongs_to :category

  delegate :user, to: :category

  validates :key, presence: true, uniqueness: true
  validates :amount,
            numericality: { greater_than: 0.00, less_than: 1_000_000_000.00 }
  validates :starts_at, presence: true, uniqueness: { scope: :category }
  validates :ends_at, uniqueness: { scope: :category }, allow_nil: true

  with_options unless: -> { starts_at.nil? } do
    before_validation :set_starts_at_to_beginning_of_month
    validates :starts_at, comparison: {
      greater_than_or_equal_to: Date.current.beginning_of_month
    }
    validates :ends_at, comparison: { greater_than_or_equal_to: :starts_at },
                        unless: -> { ends_at.nil? }
  end

  with_options unless: -> { ends_at.nil? } do
    before_validation :set_ends_at_to_end_of_month
    validates :ends_at, comparison: {
      greater_than_or_equal_to: Date.current.end_of_month
    }, unless: -> { starts_at.nil? || :starts_at > :ends_at }
  end

  before_save :update_endless_budgets, if: -> { ends_at.nil? }

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
    self.starts_at = starts_at.beginning_of_month
  end

  def set_ends_at_to_end_of_month
    self.ends_at = ends_at.end_of_month
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
