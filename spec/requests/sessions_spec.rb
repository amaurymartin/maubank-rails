# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let(:response_body) { JSON.parse(response.body).deep_symbolize_keys }

  describe 'POST /sessions' do
    def make_request
      post sessions_path, params: { session: session_create_params }
    end

    let(:session_create_json_keys) { %i[access_token expires_at] }
    let(:user) { create(:user) }
    let(:session_create_params) do
      { email: user.email, password: user.password }
    end

    context 'with success' do
      it :aggregate_failures do
        expect { make_request }.to change(AccessToken, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:session].keys)
          .to match_array(session_create_json_keys)
      end
    end

    context 'with invalid email' do
      let(:session_create_params) do
        { email: 'invalid_email', password: user.password }
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(AccessToken, :count)
        expect(response).to have_http_status(:unauthorized)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'with invalid password' do
      let(:session_create_params) do
        { email: user.email, password: 'invalid_password' }
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(AccessToken, :count)
        expect(response).to have_http_status(:unauthorized)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'with unexpected error' do
      let(:access_token) { build(:access_token, user: nil) }

      before do
        allow(AccessToken).to receive(:new).and_return(access_token)
        allow(access_token).to receive(:save).and_return(false)
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(AccessToken, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
