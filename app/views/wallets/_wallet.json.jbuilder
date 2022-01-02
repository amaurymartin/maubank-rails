# frozen_string_literal: true

json.user_key wallet.user.key
json.extract!(wallet, :key, :description, :created_at, :updated_at)
