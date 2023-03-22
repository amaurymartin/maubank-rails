# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users' do
  let(:response_body) { response.parsed_body.deep_symbolize_keys }
  let(:current_user) { create(:user) }
  let(:user_keys) do
    %i[
      key full_name nickname username email documentation
      born_on confirmed_at created_at updated_at links
    ]
  end
  let(:links_keys) { %i[self categories goals payments wallets] }

  describe 'POST /users' do
    def make_request
      post(users_path, params: { user: user_params })
    end

    let(:user_params) { attributes_for(:user) }

    context 'with valid params' do
      it :aggregate_failures do
        expect { make_request }.to change(User, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:user].keys).to match_array(user_keys)
        expect(response_body[:user][:links].keys).to match_array(links_keys)
      end
    end

    context 'with invalid params' do
      let(:user_params) { { foo: 'bar' } }

      it :aggregate_failures do
        expect { make_request }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(User).to receive(:save).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /users/:key' do
    before { get_with_token_to(user_path(user), current_user) }

    context 'when user belongs to current user' do
      let(:user) { current_user }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:user].keys).to match_array(user_keys)
        expect(response_body[:user][:links].keys).to match_array(links_keys)
      end
    end

    context 'when user does not belongs to current user' do
      let(:user) { create(:user) }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:user) { 'invalid' }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'PUT /users/:key' do
    def make_request
      put_with_token_to(user_path(user), current_user, { user: user_params })
    end

    let(:user_params) { attributes_for(:user) }

    context 'with both key and params valid' do
      let(:user) { current_user }

      it :aggregate_failures do
        expect { make_request and user.reload }.to change(user, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:user].keys).to match_array(user_keys)
        expect(response_body[:user][:links].keys).to match_array(links_keys)
      end
    end

    context 'with valid key and invalid params' do
      let(:user) { current_user }
      let(:user_params) { attributes_for(:user, nickname: nil) }

      it :aggregate_failures do
        expect { make_request and user.reload }.not_to change(user, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'when user does not belongs to current user' do
      let(:user) { create(:user) }

      it :aggregate_failures do
        expect { make_request and user.reload }.not_to change(user, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:user) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with unexpected error' do
      let(:user_params) { attributes_for(:user) }
      let(:user) { current_user }

      before do
        allow(User).to receive(:find_by).and_return(user)
        allow(user).to receive(:update).and_return(false)
      end

      it :aggregate_failures do
        expect { make_request and user.reload }.not_to change(user, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /users/:key' do
    def make_request
      patch_with_token_to(user_path(user), current_user, { user: user_params })
    end

    let(:user_params) { { full_name: Faker::Name.name } }

    context 'with both key and params valid' do
      let(:user) { current_user }

      it :aggregate_failures do
        expect { make_request and user.reload }.to change(user, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:user].keys).to match_array(user_keys)
        expect(response_body[:user][:links].keys).to match_array(links_keys)
      end
    end

    context 'with valid key and invalid params' do
      let(:user) { current_user }
      let(:user_params) { { password: 'invalid' } }

      it :aggregate_failures do
        expect { make_request and user.reload }.not_to change(user, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'when user does not belongs to current user' do
      let(:user) { create(:user) }

      it :aggregate_failures do
        expect { make_request and user.reload }.not_to change(user, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:user) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with unexpected error' do
      let(:user_params) { attributes_for(:user) }
      let(:user) { current_user }

      before do
        allow(User).to receive(:find_by).and_return(user)
        allow(user).to receive(:update).and_return(false)
      end

      it :aggregate_failures do
        expect { make_request and user.reload }.not_to change(user, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /users/:key' do
    def make_request
      delete_with_token_to(user_path(user), current_user)
    end

    context 'when user belongs to current user' do
      let(:user) { current_user }

      before { current_user }

      it :aggregate_failures do
        expect { make_request }.to change(User, :count).by(-1)
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when user does not belongs to current user' do
      let(:user) { create(:user) }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:user) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect { make_request }.not_to change(User, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with unexpected error' do
      let(:user) { current_user }

      before do
        allow(User).to receive(:find_by).and_return(user)
        allow(user).to receive(:destroy).and_return(false)
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
