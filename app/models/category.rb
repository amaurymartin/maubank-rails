# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id          :bigint           not null, primary key
#  description :text             not null
#  key         :uuid             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_categories_on_key                      (key) UNIQUE
#  index_categories_on_user_id                  (user_id)
#  index_categories_on_user_id_and_description  (user_id,description) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Category < ApplicationRecord
  include Keyable

  attr_readonly :user_id, :key, :created_at

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

  def current_budget
    budget_for(Date.current)
  end

  def budget_for(date)
    budgets.for(date).first
  end
end
