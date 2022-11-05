# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Application' do
  let(:user) { create(:user) }
  let(:access_token) { user.access_tokens.build }
  let(:plain_access_token) { access_token.send(:generated_token) }

  controller do
    def foo; end

    def bar
      raise ActiveRecord::RecordNotFound
    end
  end

  describe '#authenticate' do
    before do
      routes.draw { get 'foo', to: 'anonymous#foo' }

      request.headers['Authorization'] = 'Token invalid'
      get :foo, format: :json
    end

    context 'with unusable access token' do
      it :aggregate_failures do
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to be_empty
      end
    end
  end

  describe '#current_user' do
    before do
      routes.draw { get 'foo', to: 'anonymous#foo' }

      request.headers['Authorization'] = "Token #{plain_access_token}"
      access_token.save

      get :foo, format: :json
    end

    it { expect(controller.current_user).to eq(user) }
  end

  describe '#record_not_found' do
    before do
      routes.draw { get 'bar', to: 'anonymous#bar' }

      request.headers['Authorization'] = "Token #{plain_access_token}"
      access_token.save

      get :bar, format: :json
    end

    it :aggregate_failures do
      expect(response).to have_http_status(:not_found)
      expect(response.body).to be_empty
    end
  end
end
