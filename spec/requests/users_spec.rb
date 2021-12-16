# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users', type: :request do
  let(:response_body) { JSON.parse(response.body).deep_symbolize_keys }
  let(:user_show_json_keys) do
    %i[
      key full_name nickname username email documentation
      date_of_birth confirmed_at created_at updated_at
    ]
  end

  describe 'POST /users' do
    def make_request
      post users_path, params: { user: user_create_params }
    end

    context 'when user params are valid' do
      let(:user_create_params) { attributes_for(:user) }

      it :aggregate_failures do
        expect { make_request }.to change(User, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:user].keys).to match_array(user_show_json_keys)
      end
    end

    context 'when user params are invalid' do
      let(:user_create_params) { { foo: 'bar' } }

      it :aggregate_failures do
        expect { make_request }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end
  end

  describe 'GET /users/:key' do
    before { get user_path(user_key) }

    context 'when key is valid' do
      let(:user_key) { user.key }
      let(:user) { create(:user) }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:user].keys).to match_array(user_show_json_keys)
      end
    end

    context 'when key is invalid' do
      let(:user_key) { 'invalid' }

      it { expect(response).to have_http_status(:not_found) }
    end
  end

  describe 'PUT /users/:key' do
    def make_request
      put user_path(user_key), params: { user: user_put_params }
    end

    let(:user) { create(:user) }
    let(:user_put_params) { attributes_for(:user) }

    context 'when both key and params are valid' do
      let(:user_key) { user.key }

      it :aggregate_failures do
        expect { make_request and user.reload }.to change(user, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:user].keys).to match_array(user_show_json_keys)
      end
    end

    context 'when key is valid but params are invalid' do
      let(:user_key) { user.key }
      let(:user_put_params) { attributes_for(:user, nickname: nil) }

      it :aggregate_failures do
        expect { make_request and user.reload }.not_to change(user, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'when key is invalid but params are valid' do
      let(:user_key) { 'invalid' }

      before { make_request }

      it { expect(response).to have_http_status(:not_found) }
    end
  end

  describe 'PATCH /users/:key' do
    def make_request
      patch user_path(user_key), params: { user: user_patch_params }
    end

    let(:user) { create(:user) }
    let(:user_patch_params) { { full_name: Faker::Name.name } }

    context 'when both key and params are valid' do
      let(:user_key) { user.key }

      it :aggregate_failures do
        expect { make_request and user.reload }.to change(user, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:user].keys).to match_array(user_show_json_keys)
      end
    end

    context 'when key is valid but params are invalid' do
      let(:user_key) { user.key }
      let(:user_patch_params) { { password: 'invalid' } }

      it :aggregate_failures do
        expect { make_request and user.reload }.not_to change(user, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'when key is invalid but params are valid' do
      let(:user_key) { 'invalid' }

      before { make_request }

      it { expect(response).to have_http_status(:not_found) }
    end
  end

  describe 'DELETE /users/:key' do
    def make_request
      delete user_path(user_key)
    end

    let!(:user) { create(:user) }

    context 'when key is valid' do
      let(:user_key) { user.key }

      it :aggregate_failures do
        expect { make_request }.to change(User, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when user has not been destroyed' do
      let(:user_key) { user.key }

      before do
        allow(user).to receive(:destroy).and_return(false)
        allow(User).to receive(:find_by).and_return(user)
      end

      it :aggregate_failures do
        allow(user).to receive(:destroyed?).and_return(false)
        expect { make_request }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when key is invalid' do
      let(:user_key) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect { make_request }.not_to change(User, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
