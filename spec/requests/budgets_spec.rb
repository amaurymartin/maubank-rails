# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Budgets', type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category, user:) }
  let(:response_body) { JSON.parse(response.body).deep_symbolize_keys }
  let(:budget_show_json_keys) do
    %i[user_key category_key key amount starts_at ends_at created_at updated_at]
  end
  let(:budget_links_json_keys) { %i[user category] }

  describe 'POST /categories/:category_key/budgets' do
    def make_request
      post_with_token_to(
        category_budgets_path(category), user, { budget: budget_create_params }
      )
    end

    context 'with valid params' do
      let(:budget_create_params) { attributes_for(:budget) }

      it :aggregate_failures do
        expect { make_request }.to change(Budget, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:budget].keys)
          .to match_array budget_show_json_keys
        expect(response_body[:links].keys)
          .to match_array budget_links_json_keys
        expect(Budget.last.user).to eq(user)
      end
    end

    context 'with invalid params' do
      let(:budget_create_params) { { foo: 'bar' } }

      it :aggregate_failures do
        expect { make_request }.not_to change(Budget, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'when category do not belongs to logged user' do
      let(:budget_create_params) { attributes_for(:budget) }
      let(:category) { create(:category) }

      it :aggregate_failures do
        expect { make_request }.not_to change(Budget, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'GET /budgets/:key' do
    def make_request
      get_with_token_to(budget_path(budget), user)
    end

    let(:budget) { create(:budget, category:) }

    before { make_request }

    context 'when budget belongs to logged user' do
      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:budget].keys).to match_array budget_show_json_keys
        expect(response_body[:links].keys).to match_array budget_links_json_keys
      end
    end

    context 'when budget not belongs to logged user' do
      let(:budget) { create(:budget) }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:budget) { 'invalid' }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'PUT /budgets/:key' do
    def make_request
      put_with_token_to budget_path(budget), user, { budget: budget_put_params }
    end

    let(:budget) { create(:budget, category:) }
    let(:budget_put_params) { attributes_for(:budget, amount: 4.20) }

    context 'with both key and params valid' do
      it :aggregate_failures do
        expect { make_request and budget.reload }.to change(budget, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:budget].keys).to match_array budget_show_json_keys
        expect(response_body[:links].keys).to match_array budget_links_json_keys
      end
    end

    context 'with valid key and invalid params' do
      let(:budget_put_params) { attributes_for(:budget, amount: nil) }

      it :aggregate_failures do
        expect { make_request and budget.reload }
          .not_to change(budget, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'with another users budget' do
      let(:budget) { create(:budget) }

      it :aggregate_failures do
        expect { make_request and budget.reload }
          .not_to change(budget, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:budget) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'PATCH /budgets/:key' do
    def make_request
      patch_with_token_to(
        budget_path(budget), user, { budget: budget_patch_params }
      )
    end

    let(:budget) { create(:budget, category:) }
    let(:budget_patch_params) do
      attributes_for(:budget, description: 'Patched')
    end

    context 'with both key and params valid' do
      it :aggregate_failures do
        expect { make_request and budget.reload }.to change(budget, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:budget].keys).to match_array budget_show_json_keys
        expect(response_body[:links].keys).to match_array budget_links_json_keys
      end
    end

    context 'with valid key and invalid params' do
      let(:budget_patch_params) { attributes_for(:budget, amount: nil) }

      it :aggregate_failures do
        expect { make_request and budget.reload }
          .not_to change(budget, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'with another users key' do
      let(:budget) { create(:budget) }

      it :aggregate_failures do
        expect { make_request and budget.reload }
          .not_to change(budget, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:budget) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'DELETE /budgets/:key' do
    def make_request
      delete_with_token_to(budget_path(budget), user)
    end

    let!(:budget) { create(:budget, category:) }

    context 'with valid key' do
      it :aggregate_failures do
        expect { make_request }.to change(Budget, :count).by(-1)
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'with errors' do
      let(:budget_instance) { instance_double(budget) }

      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Budget).to receive(:destroy).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(Budget, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with another users key' do
      let(:budget) { create(:budget) }

      it :aggregate_failures do
        expect { make_request }.not_to change(Budget, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:budget) { 'invalid' }

      it :aggregate_failures do
        expect { make_request }.not_to change(Budget, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end
end
