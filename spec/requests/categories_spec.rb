# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Categories', type: :request do
  let(:user) { create(:user) }
  let(:response_body) { JSON.parse(response.body).deep_symbolize_keys }
  let(:category_show_json_keys) do
    %i[user_key key description created_at updated_at]
  end
  let(:category_links_json_keys) { :user }

  describe 'POST /categories' do
    def make_request
      post_with_token_to(
        categories_path, user, { category: category_create_params }
      )
    end

    context 'with valid params' do
      let(:category_create_params) { attributes_for(:category) }

      it :aggregate_failures do
        expect { make_request }.to change(Category, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:category].keys)
          .to match_array category_show_json_keys
        expect(response_body[:links].keys)
          .to match_array category_links_json_keys
        expect(Category.last.user).to eq(user)
      end
    end

    context 'with invalid params' do
      let(:category_create_params) { { foo: 'bar' } }

      it :aggregate_failures do
        expect { make_request }.not_to change(Category, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end
  end

  describe 'GET /categories' do
    def make_request
      get_with_token_to(categories_path, user)
    end

    context 'when user has no categories' do
      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:categories]).to be_empty
      end
    end

    context 'when user has at least one category' do
      before do
        create_list(:category, 2, user:)
        make_request
      end

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:categories].first.keys)
          .to match_array(category_show_json_keys)
        expect(response_body[:categories].first[:user_key]).to eq(user.key)
        expect(response_body[:categories].size).to eq(user.categories.count)
      end
    end
  end

  describe 'GET /categories/:key' do
    def make_request
      get_with_token_to(category_path(category), user)
    end

    let(:category) { create(:category, user:) }

    before { make_request }

    context 'when category belongs to logged user' do
      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:category].keys)
          .to match_array category_show_json_keys
        expect(response_body[:links].keys)
          .to match_array category_links_json_keys
      end
    end

    context 'when category not belongs to logged user' do
      let(:category) { create(:category) }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'PUT /categories/:key' do
    def make_request
      put_with_token_to(
        category_path(category), user, { category: category_put_params }
      )
    end

    let(:category) { create(:category, user:) }
    let(:category_put_params) do
      attributes_for(:category, description: 'Updated')
    end

    context 'with both key and params valid' do
      it :aggregate_failures do
        expect { make_request and category.reload }
          .to change(category, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:category].keys)
          .to match_array category_show_json_keys
        expect(response_body[:links].keys)
          .to match_array category_links_json_keys
      end
    end

    context 'with valid key and invalid params' do
      let(:category_put_params) { attributes_for(:category, description: nil) }

      it :aggregate_failures do
        expect { make_request and category.reload }
          .not_to change(category, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'with another users key' do
      let(:category) { create(:category) }

      it :aggregate_failures do
        expect { make_request and category.reload }
          .not_to change(category, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:category) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'PATCH /categories/:key' do
    def make_request
      patch_with_token_to(
        category_path(category), user, { category: category_patch_params }
      )
    end

    let(:category) { create(:category, user:) }
    let(:category_patch_params) do
      attributes_for(:category, description: 'Patched')
    end

    context 'with both key and params valid' do
      it :aggregate_failures do
        expect { make_request and category.reload }
          .to change(category, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:category].keys)
          .to match_array category_show_json_keys
        expect(response_body[:links].keys)
          .to match_array category_links_json_keys
      end
    end

    context 'with valid key and invalid params' do
      let(:category_patch_params) do
        attributes_for(:category, description: nil)
      end

      it :aggregate_failures do
        expect { make_request and category.reload }
          .not_to change(category, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'with another users key' do
      let(:category) { create(:category) }

      it :aggregate_failures do
        expect { make_request and category.reload }
          .not_to change(category, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:category) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'DELETE /categories/:key' do
    def make_request
      delete_with_token_to(category_path(category), user)
    end

    let!(:category) { create(:category, user:) }

    context 'with valid key' do
      it :aggregate_failures do
        expect { make_request }.to change(Category, :count).by(-1)
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'with errors' do
      let(:category_instance) { instance_double(category) }

      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Category).to receive(:destroy).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(Category, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with another users key' do
      let(:category) { create(:category) }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:category) { 'invalid' }

      it :aggregate_failures do
        expect { make_request }.not_to change(Category, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end
end
