# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Categories' do
  let(:response_body) { response.parsed_body.deep_symbolize_keys }
  let(:current_user) { create(:user) }
  let(:category_keys) { %i[key description created_at updated_at links] }
  let(:budget_keys) { %i[key amount starts_at ends_at] }
  let(:links_keys) { %i[self] }

  describe 'POST /categories' do
    def make_request
      post_with_token_to(
        categories_path, current_user, { category: category_params }
      )
    end

    let(:category_params) { attributes_for(:category) }

    context 'with valid params' do
      it 'must not have any budget', :aggregate_failures do
        expect { make_request }.to change(Category, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:category].keys).to match_array(category_keys)
        expect(response_body[:category][:budget]).not_to be_present
        expect(response_body[:category][:links].keys).to match_array(links_keys)
        expect(Category.last.user).to eq(current_user)
      end
    end

    context 'with invalid params' do
      let(:category_params) { { foo: 'bar' } }

      it :aggregate_failures do
        expect { make_request }.not_to change(Category, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Category).to receive(:save).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(Category, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /categories' do
    def make_request
      get_with_token_to(categories_path, current_user)
    end

    context 'when current user has no categories' do
      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:categories]).to be_empty
      end
    end

    context 'when current user has at least one category - without budget' do
      before do
        create_list(:category, 2, user: current_user)
        make_request
      end

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:categories].first.keys)
          .to match_array(category_keys)
        expect(response_body[:categories].first[:budget]).not_to be_present
        expect(response_body[:categories].first[:links].keys)
          .to match_array(links_keys)
        expect(response_body[:categories].size)
          .to eq(current_user.categories.count)
      end
    end

    context 'when current user has at least one category - with budget' do
      let(:category_keys) do
        %i[key description created_at updated_at budget links]
      end
      let(:links_keys) { %i[self budget] }

      before do
        create(:category, :with_budget, user: current_user)
        make_request
      end

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:categories].first.keys)
          .to match_array(category_keys)
        expect(response_body[:categories].first[:budget].keys)
          .to match_array(budget_keys)
        expect(response_body[:categories].first[:links].keys)
          .to match_array(links_keys)
        expect(response_body[:categories].size)
          .to eq(current_user.categories.count)
      end
    end

    context 'when more than one user has categories' do
      before do
        create(:category, user: current_user)
        create(:category, user: create(:user))
        make_request
      end

      it "must ignore other user's categories", :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:categories].first.keys)
          .to match_array(category_keys)
        expect(response_body[:categories].size)
          .to eq(current_user.categories.count)
        expect(Category.count).to eq(2)
      end
    end
  end

  describe 'GET /categories/:key' do
    def make_request
      get_with_token_to(category_path(category), current_user)
    end

    let(:category) { create(:category, user: current_user) }

    before { make_request }

    context 'when category belongs to current user - without budget' do
      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:category].keys).to match_array(category_keys)
        expect(response_body[:category][:budget]).not_to be_present
        expect(response_body[:category][:links].keys).to match_array(links_keys)
      end
    end

    context 'when category belongs to current user - with budget' do
      let(:category) { create(:category, :with_budget, user: current_user) }
      let(:category_keys) do
        %i[key description created_at updated_at budget links]
      end
      let(:links_keys) { %i[self budget] }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:category].keys).to match_array(category_keys)
        expect(response_body[:category][:budget].keys)
          .to match_array(budget_keys)
        expect(response_body[:category][:links].keys).to match_array(links_keys)
      end
    end

    context 'when category not belongs to current user' do
      let(:category) { create(:category) }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:category) { 'invalid' }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'PUT /categories/:key' do
    def make_request
      put_with_token_to(
        category_path(category), current_user, { category: category_params }
      )
    end

    let(:category) { create(:category, user: current_user) }
    let(:category_params) { attributes_for(:category) }

    context 'with both key and params valid - without budget' do
      it :aggregate_failures do
        expect { make_request and category.reload }
          .to change(category, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:category].keys).to match_array(category_keys)
        expect(response_body[:category][:budget]).not_to be_present
        expect(response_body[:category][:links].keys).to match_array(links_keys)
      end
    end

    context 'with both key and params valid - with budget' do
      let(:category) { create(:category, :with_budget, user: current_user) }
      let(:category_keys) do
        %i[key description created_at updated_at budget links]
      end
      let(:links_keys) { %i[self budget] }

      it :aggregate_failures do
        expect { make_request and category.reload }
          .to change(category, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:category].keys).to match_array(category_keys)
        expect(response_body[:category][:budget].keys)
          .to match_array(budget_keys)
        expect(response_body[:category][:links].keys).to match_array(links_keys)
      end
    end

    context 'with valid key and invalid params' do
      let(:category_params) { attributes_for(:category, description: nil) }

      it :aggregate_failures do
        expect { make_request and category.reload }
          .not_to change(category, :attributes)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'when category does not belongs to current user' do
      let(:category) { create(:category) }

      it :aggregate_failures do
        expect { make_request and category.reload }
          .not_to change(category, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:category) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Category).to receive(:update).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request and category.reload }
          .not_to change(category, :attributes)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'PATCH /categories/:key' do
    def make_request
      patch_with_token_to(
        category_path(category), current_user, { category: category_params }
      )
    end

    let(:category) { create(:category, user: current_user) }
    let(:category_params) { { description: 'Patched' } }

    context 'with both key and params valid - without budget' do
      it :aggregate_failures do
        expect { make_request and category.reload }
          .to change(category, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:category].keys).to match_array(category_keys)
        expect(response_body[:category][:budget]).not_to be_present
        expect(response_body[:category][:links].keys).to match_array(links_keys)
      end
    end

    context 'with both key and params valid - with budget' do
      let(:category) { create(:category, :with_budget, user: current_user) }
      let(:category_keys) do
        %i[key description created_at updated_at budget links]
      end
      let(:links_keys) { %i[self budget] }

      it :aggregate_failures do
        expect { make_request and category.reload }
          .to change(category, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:category].keys).to match_array(category_keys)
        expect(response_body[:category][:budget].keys)
          .to match_array(budget_keys)
        expect(response_body[:category][:links].keys).to match_array(links_keys)
      end
    end

    context 'with valid key and invalid params' do
      let(:category_params) { { description: nil } }

      it :aggregate_failures do
        expect { make_request and category.reload }
          .not_to change(category, :attributes)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'when category does not belongs to current user' do
      let(:category) { create(:category) }

      it :aggregate_failures do
        expect { make_request and category.reload }
          .not_to change(category, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:category) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Category).to receive(:update).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request and category.reload }
          .not_to change(category, :attributes)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /categories/:key' do
    def make_request
      delete_with_token_to(category_path(category), current_user)
    end

    let!(:category) { create(:category, user: current_user) }

    context 'when category belongs to current user' do
      it :aggregate_failures do
        expect { make_request }.to change(Category, :count).by(-1)
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when category does not belongs to current user' do
      let(:category) { create(:category) }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:category) { 'invalid' }

      it :aggregate_failures do
        expect { make_request }.not_to change(Category, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Category).to receive(:destroy).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(Category, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
