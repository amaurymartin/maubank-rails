# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Wallets::Payments' do
  let(:response_body) { response.parsed_body.deep_symbolize_keys }
  let(:current_user) { create(:user) }
  let(:wallet) { create(:wallet, user: current_user) }
  let(:category) { create(:category, user: current_user) }
  let(:payment_keys) do
    %i[key effective_date amount created_at updated_at wallet links]
  end
  let(:wallet_keys) { %i[key description balance] }
  let(:category_keys) { %i[key description] }
  let(:links_keys) { %i[self wallet] }

  describe 'POST /wallets/:wallet_key/payments' do
    def make_request
      post_with_token_to(
        wallet_payments_path(wallet), current_user, { payment: payment_params }
      )
    end

    let(:payment_params) { attributes_for(:payment) }

    context 'without category' do
      it :aggregate_failures do
        expect { make_request }.to change(Payment, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:payment][:wallet].keys).to match_array wallet_keys
        expect(response_body[:payment][:category]).not_to be_present
        expect(response_body[:payment][:links].keys).to match_array(links_keys)
        expect(Payment.last.user).to eq(current_user)
        expect(Payment.last.wallet).to eq(wallet)
        expect(Payment.last.category).to be_nil
      end
    end

    context 'with category' do
      let(:payment_params) do
        attributes_for(:payment, category: { key: category.key })
      end
      let(:payment_keys) do
        %i[
          key effective_date amount created_at updated_at wallet category links
        ]
      end
      let(:links_keys) { %i[self wallet category] }

      it :aggregate_failures do
        expect { make_request }.to change(Payment, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:payment][:wallet].keys).to match_array wallet_keys
        expect(response_body[:payment][:category].keys)
          .to match_array(category_keys)
        expect(response_body[:payment][:links].keys).to match_array(links_keys)
        expect(Payment.last.user).to eq(current_user)
        expect(Payment.last.wallet).to eq(wallet)
        expect(Payment.last.category).to eq(category)
      end
    end

    context 'with invalid params' do
      let(:payment_params) { { foo: 'bar' } }

      it :aggregate_failures do
        expect { make_request }.not_to change(Payment, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'when wallet does not belongs to current user' do
      let(:wallet) { create(:wallet) }

      it :aggregate_failures do
        expect { make_request }.not_to change(Payment, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when category is invalid' do
      let(:payment_params) { attributes_for(:payment, category: 'foo') }

      it :aggregate_failures do
        expect { make_request }.to change(Payment, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:payment][:wallet].keys).to match_array wallet_keys
        expect(response_body[:payment][:category]).not_to be_present
        expect(response_body[:payment][:links].keys).to match_array(links_keys)
        expect(Payment.last.user).to eq(current_user)
        expect(Payment.last.wallet).to eq(wallet)
        expect(Payment.last.category).to be_nil
      end
    end

    context "when category's key is invalid" do
      let(:payment_params) do
        attributes_for(:payment, category: { key: 'foo' })
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(Payment, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when category does not belongs to current user' do
      let(:payment_params) do
        attributes_for(:payment, category: { key: create(:category).key })
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(Payment, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Payment).to receive(:save).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(Payment, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /wallets/:wallet_key/payments' do
    def make_request
      get_with_token_to(wallet_payments_path(wallet), current_user)
    end

    context "when current user's wallet has no payments" do
      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payments]).to be_empty
      end
    end

    context "when user's wallet has at least one payment without category" do
      before do
        create_list(:payment, 2, wallet:)
        make_request
      end

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payments].first.keys).to match_array(payment_keys)
        expect(response_body[:payments].first[:wallet].keys)
          .to match_array(wallet_keys)
        expect(response_body[:payments].first[:category]).not_to be_present
        expect(response_body[:payments].first[:links].keys)
          .to match_array(links_keys)
        expect(response_body[:payments].size).to eq(wallet.payments.size)
      end
    end

    context "when user's wallet has at least one payment with same category" do
      let(:payment_keys) do
        %i[
          key effective_date amount created_at updated_at wallet category links
        ]
      end
      let(:links_keys) { %i[self wallet category] }

      before do
        create_list(:payment, 2, wallet:, category:)
        make_request
      end

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payments].first.keys).to match_array(payment_keys)
        expect(response_body[:payments].first[:wallet].keys)
          .to match_array(wallet_keys)
        expect(response_body[:payments].first[:category].keys)
          .to match_array(category_keys)
        expect(response_body[:payments].first[:links].keys)
          .to match_array(links_keys)
        expect(response_body[:payments].size).to eq(wallet.payments.size)
      end
    end

    context 'when wallet has at least one payment with multiple category' do
      let(:payment_keys) do
        %i[
          key effective_date amount created_at updated_at wallet category links
        ]
      end
      let(:links_keys) { %i[self wallet category] }

      before do
        create(:payment, wallet:, category:)
        create(
          :payment, wallet:, category: create(:category, user: current_user)
        )
        make_request
      end

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payments].first.keys).to match_array(payment_keys)
        expect(response_body[:payments].first[:wallet].keys)
          .to match_array(wallet_keys)
        expect(response_body[:payments].first[:category].keys)
          .to match_array(category_keys)
        expect(response_body[:payments].first[:links].keys)
          .to match_array(links_keys)
        expect(response_body[:payments].size).to eq(wallet.payments.size)
      end
    end

    context 'when more than one wallet has payments - current user' do
      before do
        create(:payment, wallet:)
        create(:payment, wallet: create(:wallet, user: current_user))
        make_request
      end

      it "must ignore other wallets's payments", :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payments].size).to eq(wallet.payments.size)
        expect(Payment.count).to eq(2)
      end
    end

    context 'when more than one wallet has payments - other user' do
      before do
        create(:payment, wallet:)
        create(:payment, wallet: create(:wallet))
        make_request
      end

      it "must ignore other user's payments", :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payments].size).to eq(wallet.payments.size)
        expect(Payment.count).to eq(2)
      end
    end
  end
end
