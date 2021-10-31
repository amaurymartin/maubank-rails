# frozen_string_literal: true

module Keyable
  extend ActiveSupport::Concern

  included do
    before_validation :set_key, on: :create

    define_method 'set_key' do
      self[:key] ||= SecureRandom.uuid
    end
  end
end
