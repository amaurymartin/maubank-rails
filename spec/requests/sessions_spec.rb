# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sessions' do
  let(:response_body) { response.parsed_body.deep_symbolize_keys }
  let(:current_user) { create(:user) }
  let(:session_keys) { %i[access_token expires_at] }

  describe 'POST /sessions' do
    def make_request
      post(sessions_path, params: { session: session_params })
    end

    let(:session_params) do
      { email: current_user.email, password: current_user.password }
    end

    context 'with success' do
      it :aggregate_failures do
        expect { make_request }.to change(AccessToken, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:session].keys).to match_array(session_keys)
      end
    end

    context 'with invalid email' do
      let(:session_params) do
        { email: 'invalid_email', password: current_user.password }
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(AccessToken, :count)
        expect(response).to have_http_status(:unauthorized)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'with valid but wrong email' do
      let(:session_params) do
        { email: 'wrong@email.com', password: current_user.password }
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(AccessToken, :count)
        expect(response).to have_http_status(:unauthorized)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'with wrong password' do
      let(:session_params) do
        { email: current_user.email, password: 'wrong_password' }
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(AccessToken, :count)
        expect(response).to have_http_status(:unauthorized)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(AccessToken).to receive(:save).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(AccessToken, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
