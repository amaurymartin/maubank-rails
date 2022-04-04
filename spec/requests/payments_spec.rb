# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Payments', type: :request do
  let(:user) { create(:user) }
  let(:wallet) { create(:wallet, user:) }
  let(:response_body) { JSON.parse(response.body).deep_symbolize_keys }
  let(:payment_keys) { %i[key effective_date amount created_at updated_at] }
  let(:wallet_keys) { %i[key description] }
  let(:category_keys) { %i[key description] }
  let(:links_keys) { %i[wallet category self] }

  describe 'GET /payments' do
    def make_request
      get_with_token_to(payments_path, user)
    end

    let(:payment_keys) do
      %i[key effective_date amount created_at updated_at wallet category links]
    end

    context 'when user has no payments' do
      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payments]).to be_empty
      end
    end

    context 'when user has categorized payments in several wallets' do
      before do
        create(:payment, wallet:)
        create(:payment, wallet: create(:wallet, user:))
        make_request
      end

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payments].first.keys)
          .to match_array(payment_keys)
        expect(response_body[:payments].first[:wallet][:description])
          .not_to eq(response_body[:payments].second[:wallet])
        expect(response_body[:payments].first[:links].keys)
          .to match_array links_keys
        expect(response_body[:payments].size).to eq(user.payments.count)
      end
    end

    context 'when user has uncategorized payments in several wallets' do
      let(:payment_keys) do
        %i[key effective_date amount created_at updated_at wallet links]
      end
      let(:links_keys) { %i[wallet self] }

      before do
        create_list(:payment, 2, :uncategorized, wallet:)
        make_request
      end

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payments].first.keys).to match_array(payment_keys)
        expect(response_body[:payments].first[:wallet][:description])
          .to eq(wallet.description)
        expect(response_body[:payments].first[:category]).not_to be_present
        expect(response_body[:payments].first[:links].keys)
          .to match_array(links_keys)
        expect(response_body[:payments].size).to eq(user.payments.count)
      end
    end
  end

  describe 'GET /payments/:key' do
    def make_request
      get_with_token_to(payment_path(payment), user)
    end

    let(:payment) { create(:payment, wallet:) }

    before { make_request }

    context 'when categorized payment belongs to current user' do
      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:category]).to be_present
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:links].keys).to match_array(links_keys)
      end
    end

    context 'when uncategorized payment belongs to current user' do
      let(:payment) { create(:payment, :uncategorized, wallet:) }
      let(:links_keys) { %i[wallet self] }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:category]).not_to be_present
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:links].keys).to match_array(links_keys)
      end
    end

    context 'when payment does not belongs to current user' do
      let(:payment) { create(:payment) }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:payment) { 'invalid' }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'PUT /payments/:key' do
    def make_request
      put_with_token_to(
        payment_path(payment), user, { payment: payment_put_params }
      )
    end

    let(:payment) { create(:payment, wallet:) }
    let(:payment_put_params) { attributes_for(:payment, amount: 4.20) }

    context "when new payment's category belongs to current user" do
      let(:new_category) { create(:category, user:) }
      let(:payment_put_params) do
        attributes_for(:payment, category: { key: new_category.key })
      end

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .to change(payment, :category).to(new_category)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:links].keys).to match_array(links_keys)
      end
    end

    context "when new payment's category does not belongs to current user" do
      let(:new_category) { create(:category) }
      let(:payment_put_params) do
        attributes_for(:payment, category: { key: new_category.key })
      end

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context "when new payment's category is nil" do
      let(:links_keys) { %i[wallet self] }
      let(:category) { create(:category, user:) }
      let(:payment) { create(:payment, wallet:, category:) }
      let(:payment_put_params) do
        attributes_for(:payment, category: { key: nil })
      end

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .to change(payment, :category).from(category).to(nil)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:links].keys).to match_array(links_keys)
      end
    end

    context "when new payment's category is the same" do
      let(:category) { payment.category }
      let(:payment_put_params) do
        attributes_for(:payment, category: { key: category.key })
      end

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :category)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys)
          .to match_array payment_keys
        expect(response_body[:links].keys)
          .to match_array links_keys
      end
    end

    context 'with both key and params valid' do
      let(:links_keys) { %i[wallet self] }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .to change(payment, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys)
          .to match_array payment_keys
        expect(response_body[:links].keys)
          .to match_array links_keys
      end
    end

    context 'with valid key and invalid params' do
      let(:payment_put_params) { attributes_for(:payment, amount: nil) }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'when payment does not belongs to current user' do
      let(:payment) { create(:payment) }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:payment) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'PATCH /payments/:key' do
    def make_request
      patch_with_token_to(
        payment_path(payment), user, { payment: payment_patch_params }
      )
    end

    let(:payment) { create(:payment, wallet:) }
    let(:payment_patch_params) { { amount: 4.20 } }

    context "when new payment's category belongs to current user" do
      let(:new_category) { create(:category, user:) }
      let(:payment_patch_params) { { category: { key: new_category.key } } }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .to change(payment, :category).to(new_category)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:links].keys).to match_array(links_keys)
      end
    end

    context "when new payment's category does not belongs to current user" do
      let(:new_category) { create(:category) }
      let(:payment_patch_params) { { category: { key: new_category.key } } }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context "when new payment's category is nil" do
      let(:links_keys) { %i[wallet self] }
      let(:category) { create(:category, user:) }
      let(:payment) { create(:payment, wallet:, category:) }
      let(:payment_patch_params) { { category: { key: nil } } }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .to change(payment, :category).from(category).to(nil)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:links].keys).to match_array(links_keys)
      end
    end

    context "when new payment's category is the same" do
      let(:category) { payment.category }
      let(:payment_patch_params) { { category: { key: category.key } } }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :category)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:links].keys).to match_array(links_keys)
      end
    end

    context 'with both key and params valid' do
      let(:links_keys) { %i[wallet self] }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .to change(payment, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:links].keys).to match_array(links_keys)
      end
    end

    context 'with valid key and invalid params' do
      let(:payment_patch_params) { { amount: nil } }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'when payment does not belongs to current user' do
      let(:payment) { create(:payment) }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:payment) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'DELETE /payments/:key' do
    def make_request
      delete_with_token_to(payment_path(payment), user)
    end

    let!(:payment) { create(:payment, :uncategorized, wallet:) }

    context 'when key is valid' do
      it :aggregate_failures do
        expect { make_request }.to change(Payment, :count).by(-1)
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'with errors' do
      let(:payment_instance) { instance_double(payment) }

      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Payment).to receive(:destroy).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(Payment, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when key does not belongs to current user' do
      let(:payment) { create(:payment, :uncategorized) }

      it :aggregate_failures do
        expect { make_request }.not_to change(Payment, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:payment) { 'invalid' }

      it :aggregate_failures do
        expect { make_request }.not_to change(Payment, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end
end
