# frozen_string_literal: true

json.user do
  json.extract!(
    user,
    :key, :full_name, :nickname, :username, :email, :documentation,
    :born_on, :confirmed_at, :created_at, :updated_at
  )
end
