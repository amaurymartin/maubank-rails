# frozen_string_literal: true

# == Schema Information
#
# Table name: goals
#
#  id          :bigint           not null, primary key
#  amount      :decimal(11, 2)   not null
#  description :text             not null
#  ends_at     :date             not null
#  key         :uuid             not null
#  starts_at   :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_goals_on_key                      (key) UNIQUE
#  index_goals_on_user_id                  (user_id)
#  index_goals_on_user_id_and_description  (user_id,description) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
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
