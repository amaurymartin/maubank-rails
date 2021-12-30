# frozen_string_literal: true

class User < ApplicationRecord
  include Keyable

  with_options dependent: :delete_all do
    has_many :access_tokens
    has_many :categories
    has_many :goals
    has_many :wallets
  end

  validates :key, presence: true, uniqueness: true
  validates :full_name, presence: true, allow_nil: true
  validates :nickname, presence: true
  validates :username, presence: true, uniqueness: true, allow_nil: true
  validates :email, presence: true, uniqueness: true
  validates_email_format_of :email, disposable: true
  validates :documentation, presence: true, allow_nil: true
  validates :documentation, uniqueness: true, allow_nil: true
  validates :confirmed_at, absence: true, if: -> { new_record? }

  validate :date_of_birth_cannot_be_in_the_future

  with_options unless: -> { persisted? && password.nil? } do
    validates :password,
              presence: true,
              confirmation: true,
              length: { minimum: 8 }
    validates :password_confirmation, presence: true
  end

  with_options if: :documentation_must_be_a_brazilian_cpf? do
    validate :valid_brazilian_cpf?
    after_validation :strip_documentation
  end

  has_secure_password

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

  def date_of_birth_cannot_be_in_the_future
    return if date_of_birth.nil? || Date.current >= date_of_birth

    errors.add(:date_of_birth, :invalid)
  end

  def documentation_must_be_a_brazilian_cpf?
    documentation.present? && ActiveModel::Type::Boolean.new.cast(
      ENV.fetch('ACCEPTS_ONLY_BRAZILIAN_CPF', true)
    )
  end

  def valid_brazilian_cpf?
    return if CPF.valid?(documentation, strict: true)

    errors.add(:documentation, :invalid)
  end

  def strip_documentation
    self.documentation = CPF.new(documentation).stripped
  end
end
