# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Goals', type: :request do
  let(:response_body) { JSON.parse(response.body).deep_symbolize_keys }
  let(:current_user) { create(:user) }
  let(:goal_keys) do
    %i[key description amount starts_at ends_at created_at updated_at links]
  end
  let(:links_keys) { %i[self] }

  describe 'POST /goals' do
    def make_request
      post_with_token_to(goals_path, current_user, { goal: goal_params })
    end

    let(:goal_params) { attributes_for(:goal) }

    context 'with valid params' do
      it :aggregate_failures do
        expect { make_request }.to change(Goal, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response_body[:goal].keys).to match_array(goal_keys)
        expect(response_body[:goal][:links].keys).to match_array(links_keys)
        expect(Goal.last.user).to eq(current_user)
      end
    end

    context 'with invalid params' do
      let(:goal_params) { { foo: 'bar' } }

      it :aggregate_failures do
        expect { make_request }.not_to change(Goal, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Goal).to receive(:save).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request }.not_to change(Goal, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /goals' do
    def make_request
      get_with_token_to(goals_path, current_user)
    end

    let(:goal_keys) do
      %i[key description amount starts_at ends_at created_at updated_at links]
    end

    context 'when current user has no goals' do
      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:goals]).to be_empty
      end
    end

    context 'when current user has at least one goal' do
      before do
        create_list(:goal, 2, user: current_user)
        make_request
      end

      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:goals].first.keys).to match_array(goal_keys)
        expect(response_body[:goals].size).to eq(current_user.goals.count)
      end
    end

    context 'when more than one user has goals' do
      before do
        create(:goal, user: current_user)
        create(:goal, user: create(:user))
        make_request
      end

      it "must ignore other user's goals", :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:goals].first.keys).to match_array(goal_keys)
        expect(response_body[:goals].size).to eq(current_user.goals.count)
        expect(Goal.count).to eq(2)
      end
    end
  end

  describe 'GET /goals/:key' do
    def make_request
      get_with_token_to(goal_path(goal), current_user)
    end

    let(:goal) { create(:goal, user: current_user) }

    before { make_request }

    context 'when goal belongs to current user' do
      it :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response_body[:goal].keys).to match_array(goal_keys)
        expect(response_body[:goal][:links].keys).to match_array(links_keys)
      end
    end

    context 'when goal does not belongs to current user' do
      let(:goal) { create(:goal) }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:goal) { 'invalid' }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  describe 'PUT /goals/:key' do
    def make_request
      put_with_token_to(goal_path(goal), current_user, { goal: goal_params })
    end

    let(:goal) { create(:goal, user: current_user) }
    let(:goal_params) { attributes_for(:goal) }

    context 'with both key and params valid' do
      it :aggregate_failures do
        expect { make_request and goal.reload }.to change(goal, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:goal].keys).to match_array(goal_keys)
        expect(response_body[:goal][:links].keys).to match_array(links_keys)
      end
    end

    context 'with valid key and invalid params' do
      let(:goal_params) { attributes_for(:goal, description: nil) }

      it :aggregate_failures do
        expect { make_request and goal.reload }.not_to change(goal, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'when goal does not belongs to current user' do
      let(:goal) { create(:goal) }

      it :aggregate_failures do
        expect { make_request and goal.reload }.not_to change(goal, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:goal) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Goal).to receive(:update).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request and goal.reload }.not_to change(goal, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /goals/:key' do
    def make_request
      patch_with_token_to(goal_path(goal), current_user, { goal: goal_params })
    end

    let(:goal) { create(:goal, user: current_user) }
    let(:goal_params) { { description: 'Patched' } }

    context 'with both key and params valid' do
      it :aggregate_failures do
        expect { make_request and goal.reload }.to change(goal, :attributes)
        expect(response).to have_http_status(:ok)
        expect(response_body[:goal].keys).to match_array(goal_keys)
        expect(response_body[:goal][:links].keys).to match_array(links_keys)
      end
    end

    context 'with valid key and invalid params' do
      let(:goal_key) { goal.key }
      let(:goal_params) { attributes_for(:goal, description: nil) }

      it :aggregate_failures do
        expect { make_request and goal.reload }.not_to change(goal, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:errors]).not_to be_empty
      end
    end

    context 'when goal does not belongs to current user' do
      let(:goal) { create(:goal) }

      it :aggregate_failures do
        expect { make_request and goal.reload }.not_to change(goal, :attributes)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:goal) { 'invalid' }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with unexpected error' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Goal).to receive(:update).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it :aggregate_failures do
        expect { make_request and goal.reload }.not_to change(goal, :attributes)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /goals/:key' do
    def make_request
      delete_with_token_to(goal_path(goal), current_user)
    end

    let!(:goal) { create(:goal, user: current_user) }

    context 'when goal belongs to current user' do
      it :aggregate_failures do
        expect { make_request }.to change(Goal, :count).by(-1)
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when goal does not belongs to current user' do
      let(:goal) { create(:goal) }

      before { make_request }

      it :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'when key is invalid' do
      let(:goal) { 'invalid' }

      it :aggregate_failures do
        expect { make_request }.not_to change(Goal, :count)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    context 'with unexpected error' do
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
  end
end
