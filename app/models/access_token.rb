# frozen_string_literal: true

class AccessToken < ApplicationRecord
  TTL = ENV.fetch('ACCESS_TOKEN_TTL', 30).to_i

  attr_readonly :user_id, :token

  belongs_to :user

  validates :token, format: { with: /\w{64}/ }, uniqueness: true
  validates :revoked_at, absence: true, on: :create

  before_validation :generate_and_encrypt_token, on: :create

  scope :usable, lambda {
    where(revoked_at: nil)
      .where('created_at >= ?', Time.current - ttl_in_minutes)
      .order(created_at: :desc)
  }

  def self.ttl_in_minutes
    TTL.minutes
  end

  def revoke!
    update(revoked_at: Time.current) unless revoked?
  end

  def revoked?
    revoked_at.present? || Time.current > expires_at
  end

  def expires_at
    created_at + self.class.ttl_in_minutes
  end

  private

  def generate_and_encrypt_token
    self.token = Digest::SHA256.hexdigest(generated_token)
  end

  def generated_token
    @generated_token ||= SecureRandom.base58 if new_record?
  end
end
