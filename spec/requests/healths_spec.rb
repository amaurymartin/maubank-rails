# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Health', type: :request do
  describe 'GET /health' do
    before { get health_path }

    it :aggregate_failures do
      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_empty
    end
  end
end
