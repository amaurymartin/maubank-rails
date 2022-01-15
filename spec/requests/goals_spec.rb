# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Goals', type: :request do
  let(:user) { create(:user) }
  let(:response_body) { JSON.parse(response.body).deep_symbolize_keys }
  let(:goal_show_json_keys) do
    %i[user_key key description amount starts_at ends_at created_at updated_at]
  end
  let(:goal_links_json_keys) { :user }

  describe 'POST /goals' do
    def make_request
      post_with_token_to(goals_path, user, { goal: goal_create_params })
    end

    context 'with valid params' do
      let(:goal_create_params) { attributes_for(:goal) }

      it :aggregate_failures do
        expect { make_request }.to change(Goal, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:goal].keys).to match_array goal_show_json_keys
        expect(response_body[:links].keys).to match_array goal_links_json_keys
        expect(Goal.last.user).to eq(user)
      end
    end

    context 'with invalid params' do
      let(:goal_create_params) { { foo: 'bar' } }

      it :aggregate_failures do
        expect { make_request }.not_to change(Goal, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end
  end

  describe 'GET /goals' do
    def make_request
      get_with_token_to(goals_path, user)
    end

    context 'when user has no goals' do
      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:goals]).to be_empty
      end
    end

    context 'when user has at least one goal' do
      before do
        create_list(:goal, 2, user:)
        make_request
      end

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:goals].first.keys)
          .to match_array(goal_show_json_keys)
        expect(response_body[:goals].first[:user_key]).to eq(user.key)
        expect(response_body[:goals].size).to eq(user.goals.count)
      end
    end
  end

  describe 'GET /goals/:key' do
    def make_request
      get_with_token_to(goal_path(goal_key), user)
    end

    let(:goal) { create(:goal, user:) }

    before { make_request }

    context 'when goal belongs to logged user' do
      let(:goal_key) { goal.key }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:goal].keys).to match_array goal_show_json_keys
        expect(response_body[:links].keys).to match_array goal_links_json_keys
      end
    end

    context 'when goal not belongs to logged user' do
      let(:goal_key) { 'invalid' }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'PUT /goals/:key' do
    def make_request
      put_with_token_to(goal_path(goal_key), user, { goal: goal_put_params })
    end

    let(:goal) { create(:goal, user:) }
    let(:goal_put_params) { attributes_for(:goal, description: 'Updated') }

    context 'with both key and params valid' do
      let(:goal_key) { goal.key }

      it :aggregate_failures do
        expect { make_request and goal.reload }.to change(goal, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:goal].keys).to match_array goal_show_json_keys
        expect(response_body[:links].keys).to match_array goal_links_json_keys
      end
    end

    context 'with valid key and invalid params' do
      let(:goal_key) { goal.key }
      let(:goal_put_params) { attributes_for(:goal, description: nil) }

      it :aggregate_failures do
        expect { make_request and goal.reload }.not_to change(goal, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'with another users key' do
      let(:goal_key) { create(:goal).key }

      it :aggregate_failures do
        expect { make_request and goal.reload }.not_to change(goal, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:goal_key) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'PATCH /goals/:key' do
    def make_request
      patch_with_token_to(
        goal_path(goal_key), user, { goal: goal_patch_params }
      )
    end

    let(:goal) { create(:goal, user:) }
    let(:goal_patch_params) { attributes_for(:goal, description: 'Patched') }

    context 'with both key and params valid' do
      let(:goal_key) { goal.key }

      it :aggregate_failures do
        expect { make_request and goal.reload }.to change(goal, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:goal].keys).to match_array goal_show_json_keys
        expect(response_body[:links].keys).to match_array goal_links_json_keys
      end
    end

    context 'with valid key and invalid params' do
      let(:goal_key) { goal.key }
      let(:goal_patch_params) { attributes_for(:goal, description: nil) }

      it :aggregate_failures do
        expect { make_request and goal.reload }.not_to change(goal, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).to be_present
      end
    end

    context 'with another users key' do
      let(:goal_key) { create(:goal).key }

      it :aggregate_failures do
        expect { make_request and goal.reload }.not_to change(goal, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:goal_key) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'DELETE /goals/:key' do
    def make_request
      delete_with_token_to(goal_path(goal_key), user)
    end

    let!(:goal) { create(:goal, user:) }

    context 'with valid key' do
      let(:goal_key) { goal.key }

      it :aggregate_failures do
        expect { make_request }.to change(Goal, :count).by(-1)
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'with errors' do
      let(:goal_key) { goal.key }
      let(:goal_instance) { instance_double(Goal) }

      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Goal).to receive(:destroy).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(Goal, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with another users key' do
      let(:goal_key) { create(:goal).key }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with invalid key' do
      let(:goal_key) { 'invalid' }

      it :aggregate_failures do
        expect { make_request }.not_to change(Goal, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end
end
