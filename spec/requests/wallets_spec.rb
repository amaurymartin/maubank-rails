# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Wallets', type: :request do
  let(:user) { create(:user) }
  let(:response_body) { JSON.parse(response.body).deep_symbolize_keys }
  let(:wallet_show_json_keys) do
    %i[user_key key description created_at updated_at]
  end
  let(:wallet_links_json_keys) { :user }

  describe 'POST /wallets' do
    def make_request
      post_with_token_to(wallets_path, user, { wallet: wallet_create_params })
    end

    context 'with valid params' do
      let(:wallet_create_params) { attributes_for(:wallet) }

      it :aggregate_failures do
        expect { make_request }.to change(Wallet, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:wallet].keys).to match_array wallet_show_json_keys
        expect(response_body[:links].keys).to match_array wallet_links_json_keys
        expect(Wallet.last.user).to eq(user)
      end
    end

    context 'with invalid params' do
      let(:wallet_create_params) { { foo: 'bar' } }

      it :aggregate_failures do
        expect { make_request }.not_to change(Wallet, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end
  end

  describe 'GET /wallets' do
    def make_request
      get_with_token_to(wallets_path, user)
    end

    context 'when user has no wallets' do
      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:wallets]).to be_empty
      end
    end

    context 'when user has at least one wallet' do
      before do
        create_list(:wallet, 2, user:)
        make_request
      end

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:wallets].first.keys)
          .to match_array(wallet_show_json_keys)
        expect(response_body[:wallets].first[:user_key]).to eq(user.key)
        expect(response_body[:wallets].size).to eq(user.wallets.count)
      end
    end
  end

  describe 'PUT /wallets/:key' do
    def make_request
      put_with_token_to wallet_path(wallet), user, { wallet: wallet_put_params }
    end

    let(:wallet) { create(:wallet, user:) }
    let(:wallet_put_params) { attributes_for(:wallet, description: 'Updated') }

    context 'with both key and params valid' do
      it :aggregate_failures do
        expect { make_request and wallet.reload }.to change(wallet, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:wallet].keys).to match_array wallet_show_json_keys
        expect(response_body[:links].keys).to match_array wallet_links_json_keys
      end
    end

    context 'with valid key and invalid params' do
      let(:wallet_put_params) { attributes_for(:wallet, description: nil) }

      it :aggregate_failures do
        expect { make_request and wallet.reload }
          .not_to change(wallet, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'with another users key' do
      let(:wallet) { create(:wallet) }

      it :aggregate_failures do
        expect { make_request and wallet.reload }
          .not_to change(wallet, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:wallet) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'PATCH /wallets/:key' do
    def make_request
      patch_with_token_to(
        wallet_path(wallet), user, { wallet: wallet_patch_params }
      )
    end

    let(:wallet) { create(:wallet, user:) }
    let(:wallet_patch_params) do
      attributes_for(:wallet, description: 'Patched')
    end

    context 'with both key and params valid' do
      it :aggregate_failures do
        expect { make_request and wallet.reload }.to change(wallet, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:wallet].keys).to match_array wallet_show_json_keys
        expect(response_body[:links].keys).to match_array wallet_links_json_keys
      end
    end

    context 'with valid key and invalid params' do
      let(:wallet_patch_params) { attributes_for(:wallet, description: nil) }

      it :aggregate_failures do
        expect { make_request and wallet.reload }
          .not_to change(wallet, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'with another users key' do
      let(:wallet) { create(:wallet) }

      it :aggregate_failures do
        expect { make_request and wallet.reload }
          .not_to change(wallet, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:wallet) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'DELETE /wallets/:key' do
    def make_request
      delete_with_token_to(wallet_path(wallet), user)
    end

    let!(:wallet) { create(:wallet, user:) }

    context 'with valid key' do
      it :aggregate_failures do
        expect { make_request }.to change(Wallet, :count).by(-1)
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'with errors' do
      let(:wallet_instance) { instance_double(Wallet) }

      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Wallet).to receive(:destroy).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(Wallet, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with another users key' do
      let(:wallet) { create(:wallet) }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:wallet) { 'invalid' }

      it :aggregate_failures do
        expect { make_request }.not_to change(Wallet, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end
end
