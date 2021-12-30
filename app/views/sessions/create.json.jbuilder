# frozen_string_literal: true

json.session do
  json.access_token @plain_access_token
  json.expires_at @access_token.expires_at
end
