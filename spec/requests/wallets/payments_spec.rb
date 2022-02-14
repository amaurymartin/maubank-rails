# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Wallets::Payments', type: :request do
  let(:user) { create(:user) }
  let(:wallet) { create(:wallet, user:) }
  let(:category) { create(:category, user:) }
  let(:response_body) { JSON.parse(response.body).deep_symbolize_keys }
  let(:payment_show_json_keys) do
    %i[key effective_date amount created_at updated_at]
  end
  let(:payment_wallet_json_keys) { %i[key description] }
  let(:payment_category_json_keys) { %i[key description] }
  let(:payment_links_json_keys) { %i[wallet category self] }

  describe 'POST /wallets/:wallet_key/payments' do
    def make_request
      post_with_token_to(
        wallet_payments_path(wallet), user, { payment: payment_create_params }
      )
    end

    context 'with category' do
      let(:payment_create_params) do
        attributes_for(:payment).merge!(category: { key: category.key })
      end

      it :aggregate_failures do
        expect { make_request }.to change(Payment, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:payment].keys)
          .to match_array payment_show_json_keys
        expect(response_body[:wallet].keys)
          .to match_array payment_wallet_json_keys
        expect(response_body[:category].keys)
          .to match_array payment_category_json_keys
        expect(response_body[:links].keys)
          .to match_array payment_links_json_keys
        expect(Payment.last.user).to eq(user)
        expect(Payment.last.wallet).to eq(wallet)
        expect(Payment.last.category).to eq(category)
      end
    end

    context 'without category' do
      let(:payment_links_json_keys) { %i[wallet self] }
      let(:payment_create_params) { attributes_for(:payment) }

      it :aggregate_failures do
        expect { make_request }.to change(Payment, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:payment].keys)
          .to match_array payment_show_json_keys
        expect(response_body[:wallet].keys)
          .to match_array payment_wallet_json_keys
        expect(response_body[:category]).not_to be_present
        expect(response_body[:links].keys)
          .to match_array payment_links_json_keys
        expect(Payment.last.user).to eq(user)
        expect(Payment.last.wallet).to eq(wallet)
      end
    end

    context 'with invalid params' do
      let(:payment_create_params) { { foo: 'bar' } }

      it :aggregate_failures do
        expect { make_request }.not_to change(Payment, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'when wallet do not belongs to logged user' do
      let(:payment_create_params) { attributes_for(:payment) }
      let(:wallet) { create(:wallet) }

      it :aggregate_failures do
        expect { make_request }.not_to change(Payment, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when category do not belongs to logged user' do
      let(:payment_create_params) do
        attributes_for(:payment)
          .merge!(category: { key: create(:category).key })
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(Payment, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'GET /wallets/:wallet_key/payments' do
    def make_request
      get_with_token_to(wallet_payments_path(wallet), user)
    end

    let(:payment_index_json_keys) do
      %i[key effective_date amount created_at updated_at wallet category links]
    end

    context 'when users wallet has no payments' do
      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payments]).to be_empty
      end
    end

    context 'when users wallet has at least one payment with category' do
      before do
        create_list(:payment, 2, wallet:, category:)
        make_request
      end

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payments].first.keys)
          .to match_array(payment_index_json_keys)
        expect(response_body[:payments].first[:wallet][:description])
          .to eq(wallet.description)
        expect(response_body[:payments].first[:category][:description])
          .to eq(category.description)
        expect(response_body[:payments].first[:links].keys)
          .to match_array payment_links_json_keys
        expect(response_body[:payments].size).to eq(wallet.payments.count)
      end
    end

    context 'when users wallet has at least one payment without category' do
      let(:payment_index_json_keys) do
        %i[key effective_date amount created_at updated_at wallet links]
      end
      let(:payment_links_json_keys) { %i[wallet self] }

      before do
        create_list(:payment, 2, wallet:, category: nil)
        make_request
      end

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payments].first.keys)
          .to match_array(payment_index_json_keys)
        expect(response_body[:payments].first[:wallet][:description])
          .to eq(wallet.description)
        expect(response_body[:payments].first[:category]).not_to be_present
        expect(response_body[:payments].first[:links].keys)
          .to match_array payment_links_json_keys
        expect(response_body[:payments].size).to eq(wallet.payments.count)
      end
    end
  end
end
