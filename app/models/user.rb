# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  born_on         :date
#  confirmed_at    :datetime
#  documentation   :text
#  email           :text             not null
#  full_name       :text
#  key             :uuid             not null
#  nickname        :text             not null
#  password_digest :text             not null
#  username        :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_documentation  (documentation) UNIQUE
#  index_users_on_email          (email) UNIQUE
#  index_users_on_key            (key) UNIQUE
#  index_users_on_username       (username) UNIQUE
#
class User < ApplicationRecord
  include Keyable

  ONLY_BRAZILIAN_CPF = ActiveModel::Type::Boolean.new.cast(
    ENV.fetch('ONLY_BRAZILIAN_CPF', true)
  )

  attr_readonly :key, :email, :created_at

  has_secure_password

  with_options dependent: :delete_all do
    has_many :access_tokens
    has_many :categories
    has_many :goals
    has_many :wallets
  end

  has_many :budgets, through: :categories
  has_many :payments, through: :wallets

  validates :key, presence: true, uniqueness: true
  validates :full_name, presence: true, allow_nil: true
  validates :nickname, presence: true
  validates :username,
            presence: true,
            uniqueness: { case_sensitive: false },
            allow_nil: true
  validates :email,
            presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :born_on,
            comparison: { less_than_or_equal_to: Date.current }, allow_nil: true
  validates :confirmed_at, absence: true, on: :create

  with_options if: -> { new_record? || password.present? } do
    validates :password, confirmation: true, length: { minimum: 8 }
    validates :password_confirmation, presence: true
  end

  with_options unless: -> { documentation.nil? } do
    before_validation :strip_documentation
    validates :documentation, uniqueness: true
    validate :valid_brazilian_cpf?, if: -> { ONLY_BRAZILIAN_CPF }
  end

  def to_param
    key
  end

  def confirm!
    update(confirmed_at: Time.current) unless confirmed?
  end

  def confirmed?
    confirmed_at.present?
  end

  private

  def strip_documentation
    self.documentation = CPF.new(documentation).stripped
  end

  def valid_brazilian_cpf?
    return true if CPF.valid?(documentation, strict: true)

    errors.add(:documentation, :invalid)
  end
end
