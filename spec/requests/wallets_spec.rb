# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Wallets' do
  let(:response_body) { JSON.parse(response.body).deep_symbolize_keys }
  let(:current_user) { create(:user) }
  let(:wallet_keys) { %i[key description balance created_at updated_at links] }
  let(:links_keys) { %i[self payments] }

  describe 'POST /wallets' do
    def make_request
      post_with_token_to(wallets_path, current_user, { wallet: wallet_params })
    end

    let(:wallet_params) { attributes_for(:wallet) }

    context 'with valid params' do
      it :aggregate_failures do
        expect { make_request }.to change(Wallet, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:wallet].keys).to match_array(wallet_keys)
        expect(response_body[:wallet][:links].keys).to match_array(links_keys)
        expect(Wallet.last.user).to eq(current_user)
      end
    end

    context 'with invalid params' do
      let(:wallet_params) { { foo: 'bar' } }

      it :aggregate_failures do
        expect { make_request }.not_to change(Wallet, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Wallet).to receive(:save).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(Wallet, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /wallets' do
    def make_request
      get_with_token_to(wallets_path, current_user)
    end

    let(:wallet_keys) do
      %i[key description balance created_at updated_at links]
    end

    context 'when current user has no wallets' do
      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:wallets]).to be_empty
      end
    end

    context 'when current user has at least one wallet' do
      before do
        create_list(:wallet, 2, user: current_user)
        make_request
      end

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:wallets].first.keys).to match_array(wallet_keys)
        expect(response_body[:wallets].size).to eq(current_user.wallets.count)
      end
    end

    context 'when more than one user has wallets' do
      before do
        create(:wallet, user: current_user)
        create(:wallet, user: create(:user))
        make_request
      end

      it "must ignore other user's wallets", :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:wallets].first.keys).to match_array(wallet_keys)
        expect(response_body[:wallets].size).to eq(current_user.wallets.count)
        expect(Wallet.count).to eq(2)
      end
    end
  end

  describe 'PUT /wallets/:key' do
    def make_request
      put_with_token_to(
        wallet_path(wallet), current_user, { wallet: wallet_params }
      )
    end

    let(:wallet) { create(:wallet, user: current_user) }
    let(:wallet_params) { attributes_for(:wallet) }

    context 'with both key and params valid' do
      it :aggregate_failures do
        expect { make_request and wallet.reload }.to change(wallet, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:wallet].keys).to match_array(wallet_keys)
        expect(response_body[:wallet][:links].keys).to match_array(links_keys)
      end
    end

    context 'with valid key and invalid params' do
      let(:wallet_params) { attributes_for(:wallet, description: nil) }

      it :aggregate_failures do
        expect { make_request and wallet.reload }
          .not_to change(wallet, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'when wallet does not belongs to current user' do
      let(:wallet) { create(:wallet) }

      it :aggregate_failures do
        expect { make_request and wallet.reload }
          .not_to change(wallet, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:wallet) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Wallet).to receive(:update).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request and wallet.reload }
          .not_to change(wallet, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /wallets/:key' do
    def make_request
      patch_with_token_to(
        wallet_path(wallet), current_user, { wallet: wallet_params }
      )
    end

    let(:wallet) { create(:wallet, user: current_user) }
    let(:wallet_params) { { description: 'Patched' } }

    context 'with both key and params valid' do
      it :aggregate_failures do
        expect { make_request and wallet.reload }.to change(wallet, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:wallet].keys).to match_array(wallet_keys)
        expect(response_body[:wallet][:links].keys).to match_array(links_keys)
      end
    end

    context 'with valid key and invalid params' do
      let(:wallet_params) { { description: nil } }

      it :aggregate_failures do
        expect { make_request and wallet.reload }
          .not_to change(wallet, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'when wallet does not belongs to current user' do
      let(:wallet) { create(:wallet) }

      it :aggregate_failures do
        expect { make_request and wallet.reload }
          .not_to change(wallet, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:wallet) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Wallet).to receive(:update).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request and wallet.reload }
          .not_to change(wallet, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /wallets/:key' do
    def make_request
      delete_with_token_to(wallet_path(wallet), current_user)
    end

    let!(:wallet) { create(:wallet, user: current_user) }

    context 'when wallet belongs to current user' do
      it :aggregate_failures do
        expect { make_request }.to change(Wallet, :count).by(-1)
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when wallet does not belongs to current user' do
      let(:wallet) { create(:wallet) }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:wallet) { 'invalid' }

      it :aggregate_failures do
        expect { make_request }.not_to change(Wallet, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with unexpected error' do
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
  end
end
