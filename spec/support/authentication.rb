# frozen_string_literal: true

module Authentication
  def post_with_token_to(path, user = create_user, params = {}, headers = {})
    post path, params:, headers: with_access_token(headers, user)
  end

  def get_with_token_to(path, user = create_user, params = {}, headers = {})
    get path, params:, headers: with_access_token(headers, user)
  end

  def put_with_token_to(path, user = create_user, params = {}, headers = {})
    put path, params:, headers: with_access_token(headers, user)
  end

  def patch_with_token_to(path, user = create_user, params = {}, headers = {})
    patch path, params:, headers: with_access_token(headers, user)
  end

  def delete_with_token_to(path, user = create_user, params = {}, headers = {})
    delete path, params:, headers: with_access_token(headers, user)
  end

  private

  def create_user
    create(:user)
  end

  def with_access_token(headers, user)
    access_token = build(:access_token, user:)
    headers['Authorization'] = "Token #{access_token.send(:generated_token)}"
    access_token.save

    headers
  end
end
