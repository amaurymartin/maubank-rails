# frozen_string_literal: true

class User < ApplicationRecord
  include Keyable

  has_many :wallets, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :full_name, presence: true, unless: -> { full_name.nil? }
  validates :nickname, presence: true
  validates :username, presence: true, unless: -> { username.nil? }
  validates :username, uniqueness: true, if: -> { username.present? }
  validates :email, presence: true, uniqueness: true
  validates_email_format_of :email, disposable: true
  validates :password,
            presence: true,
            confirmation: true,
            length: { minimum: 8 }
  validates :password_confirmation,
            presence: true
  validates :documentation, presence: true, unless: -> { documentation.nil? }
  validates_cpf_format_of :documentation, if: lambda {
    documentation.present? && ActiveModel::Type::Boolean.new.cast(
      ENV.fetch('ACCEPTS_ONLY_BRAZILIAN_CPF', true)
    )
  }
  validates :documentation, uniqueness: true, if: -> { documentation.present? }
  validates :confirmed_at, absence: true, if: -> { new_record? }

  validate :date_of_birth_cannot_be_in_the_future

  has_secure_password

  def confirm!
    update(confirmed_at: Time.current) unless confirmed?
  end

  def confirmed?
    confirmed_at.present?
  end

  private

  def date_of_birth_cannot_be_in_the_future
    return if date_of_birth.nil? || Time.current.to_date >= date_of_birth

    errors.add(:date_of_birth, :invalid)
  end
end
