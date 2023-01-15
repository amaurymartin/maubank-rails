# frozen_string_literal: true

# == Schema Information
#
# Table name: wallets
#
#  id          :bigint           not null, primary key
#  balance     :decimal(11, 2)   not null
#  description :text             not null
#  key         :uuid             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_wallets_on_key                      (key) UNIQUE
#  index_wallets_on_user_id                  (user_id)
#  index_wallets_on_user_id_and_description  (user_id,description) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Wallet < ApplicationRecord
  include Keyable

  attr_readonly :user_id, :key, :created_at

  belongs_to :user

  has_many :payments, dependent: :delete_all

  validates :key, presence: true, uniqueness: true
  validates :description, presence: true,
                          uniqueness: { scope: :user, case_sensitive: false }
  validates :balance, numericality: {
    greater_than: -1_000_000_000.00, less_than: 1_000_000_000.00
  }

  def to_param
    key
  end

  def update_balance(amount)
    update(balance: balance + amount.to_f)
  end
end
