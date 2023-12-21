# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rails Health Check' do
  describe 'GET /up' do
    before { get rails_health_check_path }

    it :aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(
        <<~HEREDOC.squish
          <!DOCTYPE html><html><body style="background-color: green"></body></html>
        HEREDOC
      )
    end
  end
end
