# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Payments' do
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

  describe 'GET /payments' do
    def make_request
      get_with_token_to(payments_path, current_user)
    end

    context 'when current user has no payments' do
      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payments]).to be_empty
      end
    end

    context 'when user has uncategorized payments in several wallets' do
      let(:payment_keys) do
        %i[key effective_date amount created_at updated_at wallet links]
      end

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
        expect(response_body[:payments].size).to eq(current_user.payments.size)
      end
    end

    context 'when user has categorized payments in several wallets' do
      let(:payment_keys) do
        %i[
          key effective_date amount created_at updated_at wallet category links
        ]
      end
      let(:links_keys) { %i[self wallet category] }

      before do
        create(:payment, :categorized, wallet:)
        create(
          :payment, :categorized, wallet: create(:wallet, user: current_user)
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
        expect(response_body[:payments].size).to eq(current_user.payments.size)
      end
    end

    context 'when more than one user has payments' do
      before do
        create(:payment, wallet:)
        create(:payment, wallet: create(:wallet))
        make_request
      end

      it "must ignore other user's payments", :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payments].size).to eq(current_user.payments.size)
        expect(Payment.count).to eq(2)
      end
    end
  end

  describe 'GET /payments/:key' do
    def make_request
      get_with_token_to(payment_path(payment), current_user)
    end

    let(:payment) { create(:payment, wallet:) }

    before { make_request }

    context 'when uncategorized payment belongs to current user' do
      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:payment][:wallet].keys).to match_array wallet_keys
        expect(response_body[:payment][:category]).not_to be_present
        expect(response_body[:payment][:links].keys).to match_array(links_keys)
      end
    end

    context 'when categorized payment belongs to current user' do
      let(:payment) { create(:payment, :categorized, wallet:) }
      let(:payment_keys) do
        %i[
          key effective_date amount created_at updated_at wallet category links
        ]
      end
      let(:links_keys) { %i[self wallet category] }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:payment][:wallet].keys).to match_array wallet_keys
        expect(response_body[:payment][:category].keys)
          .to match_array(category_keys)
        expect(response_body[:payment][:links].keys).to match_array(links_keys)
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
        payment_path(payment), current_user, { payment: payment_params }
      )
    end

    let(:payment) { create(:payment, wallet:) }
    let(:payment_params) { attributes_for(:payment, category: { key: nil }) }

    context 'with both key and params valid' do
      it :aggregate_failures do
        expect { make_request and payment.reload }
          .to change(payment, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:payment][:wallet].keys).to match_array wallet_keys
        expect(response_body[:payment][:category]).not_to be_present
        expect(response_body[:payment][:links].keys).to match_array(links_keys)
      end
    end

    context 'with valid key and invalid params' do
      let(:payment_params) { attributes_for(:payment, amount: nil) }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).not_to be_empty
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

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Payment).to receive(:update).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when new payment's category is invalid" do
      let(:payment_params) { attributes_for(:payment, category: 'foo') }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :category)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:payment][:wallet].keys).to match_array wallet_keys
        expect(response_body[:payment][:category]).not_to be_present
        expect(response_body[:payment][:links].keys).to match_array(links_keys)
      end
    end

    context "when new category's key is invalid" do
      let(:payment_params) do
        attributes_for(:payment, category: { key: 'foo' })
      end

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context "when new payment's category is the same and not nil" do
      let(:payment) { create(:payment, :categorized, wallet:) }
      let(:payment_params) do
        attributes_for(:payment, category: { key: payment.category.key })
      end
      let(:payment_keys) do
        %i[
          key effective_date amount created_at updated_at wallet category links
        ]
      end
      let(:links_keys) { %i[self wallet category] }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :category)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:payment][:wallet].keys).to match_array wallet_keys
        expect(response_body[:payment][:category].keys)
          .to match_array(category_keys)
        expect(response_body[:payment][:links].keys).to match_array(links_keys)
      end
    end

    context "when new payment's category belongs to current user" do
      let(:new_category) { create(:category, user: current_user) }
      let(:payment_params) do
        attributes_for(:payment, category: { key: new_category.key })
      end
      let(:payment_keys) do
        %i[
          key effective_date amount created_at updated_at wallet category links
        ]
      end
      let(:links_keys) { %i[self wallet category] }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .to change(payment, :category).to(new_category)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:payment][:wallet].keys).to match_array wallet_keys
        expect(response_body[:payment][:category].keys)
          .to match_array(category_keys)
        expect(response_body[:payment][:links].keys).to match_array(links_keys)
      end
    end

    context "when new payment's category does not belongs to current user" do
      let(:new_category) { create(:category) }
      let(:payment_params) do
        attributes_for(:payment, category: { key: new_category.key })
      end

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'PATCH /payments/:key' do
    def make_request
      patch_with_token_to(
        payment_path(payment), current_user, { payment: payment_params }
      )
    end

    let(:payment) { create(:payment, wallet:) }
    let(:payment_params) do
      {
        amount: Faker::Number.between(from: -999_999_999.99, to: 999_999_999.99)
      }
    end

    context 'with both key and params valid' do
      it :aggregate_failures do
        expect { make_request and payment.reload }
          .to change(payment, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:payment][:wallet].keys).to match_array wallet_keys
        expect(response_body[:payment][:category]).not_to be_present
        expect(response_body[:payment][:links].keys).to match_array(links_keys)
      end
    end

    context 'with valid key and invalid params' do
      let(:payment_params) { { amount: nil } }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).not_to be_empty
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

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Payment).to receive(:update).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when new payment's category is invalid" do
      let(:payment_params) { { category: 'foo' } }

      it 'must ignore category changing', :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :category)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:payment][:wallet].keys).to match_array wallet_keys
        expect(response_body[:payment][:category]).not_to be_present
        expect(response_body[:payment][:links].keys).to match_array(links_keys)
      end
    end

    context "when new category's key is invalid" do
      let(:payment_params) { { category: { key: 'foo' } } }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context "when new payment's category is the same and not nil" do
      let(:payment) { create(:payment, :categorized, wallet:) }
      let(:payment_params) { { category: { key: payment.category.key } } }
      let(:payment_keys) do
        %i[
          key effective_date amount created_at updated_at wallet category links
        ]
      end
      let(:links_keys) { %i[self wallet category] }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :category)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:payment][:wallet].keys).to match_array wallet_keys
        expect(response_body[:payment][:category].keys)
          .to match_array(category_keys)
        expect(response_body[:payment][:links].keys).to match_array(links_keys)
      end
    end

    context "when new payment's category belongs to current user" do
      let(:new_category) { create(:category, user: current_user) }
      let(:payment_params) { { category: { key: new_category.key } } }
      let(:payment_keys) do
        %i[
          key effective_date amount created_at updated_at wallet category links
        ]
      end
      let(:links_keys) { %i[self wallet category] }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .to change(payment, :category).to(new_category)
        expect(response).to have_http_status(:ok)
        expect(response_body[:payment].keys).to match_array(payment_keys)
        expect(response_body[:payment][:wallet].keys).to match_array wallet_keys
        expect(response_body[:payment][:category].keys)
          .to match_array(category_keys)
        expect(response_body[:payment][:links].keys).to match_array(links_keys)
      end
    end

    context "when new payment's category does not belongs to current user" do
      let(:new_category) { create(:category) }
      let(:payment_params) { { category: { key: new_category.key } } }

      it :aggregate_failures do
        expect { make_request and payment.reload }
          .not_to change(payment, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'DELETE /payments/:key' do
    def make_request
      delete_with_token_to(payment_path(payment), current_user)
    end

    let!(:payment) { create(:payment, wallet:) }

    context 'when payment belongs to current user' do
      it :aggregate_failures do
        expect { make_request }.to change(Payment, :count).by(-1)
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when payment does not belongs to current user' do
      let(:payment) { create(:payment) }

      before { make_request }

      it :aggregate_failures do
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

    context 'with unexpected error' do
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
  end
end
