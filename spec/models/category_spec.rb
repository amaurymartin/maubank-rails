# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Category, type: :model do
  describe '#validate' do
    subject(:category) { build(:category) }

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

  describe '#budget_for' do
    subject(:budget_for) { category.budget_for(date) }

    let!(:category) { create(:category) }
    let!(:first_budget) do
      category.budgets.create(attributes_for(:budget, ends_at: nil))
    end
    let!(:second_budget) do
      category.budgets.create(
        attributes_for(
          :budget,
          starts_at: Date.current + 1.month,
          ends_at: Date.current + 1.month
        )
      )
    end

    context 'without budgets for the date' do
      let(:date) { Date.current - 1.month }

      it { is_expected.to be_nil }
    end

    context 'with specific budget for the date' do
      let(:date) { Date.current }

      it { is_expected.to eq(first_budget) }
    end

    context 'with maintained budget via starts_at' do
      let(:date) { Date.current + 1.month }

      it { is_expected.to eq(second_budget) }
    end

    context 'with maintained budget via ends_at' do
      let(:date) { Date.current + 2.months }

      it { is_expected.to eq(first_budget) }
    end
  end

  describe 'dependent destroy' do
    context 'with budget' do
      let(:category) { create(:category, :with_budget) }
      let(:category_budgets) { category.budgets }

      it do
        expect { category.destroy }.to change(Budget, :count)
          .by(-category_budgets.size)
      end
    end
  end

  describe 'dependent nullify' do
    context 'with payment' do
      let!(:payment) { create(:payment) }
      let(:category) { payment.category }

      it { expect { category.destroy }.not_to change(Payment, :count) }

      it do
        expect { category.destroy }.to change { payment.reload.category }
          .from(category).to(nil)
      end
    end
  end
end
