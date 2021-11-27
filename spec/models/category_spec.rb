# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Category, type: :model do
  subject(:category) { build(:category) }

  before { category.validate }

  describe '#validate' do
    it { is_expected.to be_valid }
  end

  describe '#user' do
    context 'when is nil' do
      subject(:category) { build(:category, user: nil) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#key' do
    context 'when is nil' do
      subject(:category) { build(:category, key: nil) }

      it :aggregate_failures do
        expect(category).to be_valid
        expect(category.key).to be_present
      end
    end

    context 'when is blank' do
      subject(:category) { build(:category, key: '') }

      it :aggregate_failures do
        expect(category).to be_valid
        expect(category.key).to be_present
      end
    end

    context 'when is invalid' do
      subject(:category) { build(:category, key: invalid_key) }

      let(:invalid_key) { 'invalid_key' }

      it :aggregate_failures do
        expect(category).to be_valid
        expect(category.key).not_to eq(invalid_key)
      end
    end

    context 'when already taken' do
      subject(:second_category) { build(:category, key: first_category.key) }

      let(:first_category) { create(:category) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#description' do
    context 'when is nil' do
      subject(:category) { build(:category, description: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when is blank' do
      subject(:category) { build(:category, description: '') }

      it { is_expected.to be_invalid }
    end

    context 'when is already taken by same user' do
      subject(:second_category) do
        build(:category,
              user: first_category.user,
              description: first_category.description)
      end

      let(:first_category) { create(:category) }

      it { is_expected.to be_invalid }
    end

    context 'when is already taken by same user case insensitive' do
      subject(:second_category) do
        build(:category,
              user: first_category.user,
              description: first_category.description.upcase)
      end

      let(:first_category) { create(:category) }

      it { is_expected.to be_invalid }
    end

    context 'when is already taken by other user' do
      subject(:second_category) do
        build(:category, description: first_category.description)
      end

      let(:first_category) { create(:category) }

      it { is_expected.to be_valid }
    end
  end

  describe 'dependent destroy' do
    let(:user) { create(:user, :with_category) }
    let(:user_categories) { user.categories }

    it do
      expect { user.destroy }.to change(described_class, :count)
        .by(-user_categories.size)
    end
  end
end
