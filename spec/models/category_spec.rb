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

      it :aggregate_failures do
        expect(category).to be_invalid
        expect(category.errors).to be_added(:user, :blank)
      end
    end

    context 'when is read-only' do
      subject(:category) { create(:category) }

      let(:other_user) { create(:user) }

      it do
        expect { category.update(user: other_user) && category.reload }
          .not_to change(category, :user)
      end
    end
  end

  describe '#key' do
    context 'when is nil' do
      subject(:category) { build(:category, key: nil) }

      it 'must auto generate', :aggregate_failures do
        expect(category).to be_valid
        expect(category.key).to be_present
      end
    end

    context 'when is blank' do
      subject(:category) { build(:category, key: '') }

      it 'must auto generate', :aggregate_failures do
        expect(category).to be_valid
        expect(category.key).to be_present
      end
    end

    context 'when is invalid' do
      subject(:category) { build(:category, key: invalid_key) }

      let(:invalid_key) { 'invalid_key' }

      it 'must auto generate', :aggregate_failures do
        expect(category).to be_valid
        expect(category.key).not_to eq(invalid_key)
      end
    end

    context 'when already taken' do
      subject(:second_category) { build(:category, key: first_category.key) }

      let(:first_category) { create(:category) }

      it :aggregate_failures do
        expect(second_category).to be_invalid
        expect(second_category.errors)
          .to be_added(:key, :taken, { value: first_category.key })
      end
    end

    context 'when is read-only' do
      subject(:category) { create(:category) }

      it do
        expect { category.update(key: SecureRandom.uuid) && category.reload }
          .not_to change(category, :key)
      end
    end
  end

  describe '#description' do
    context 'when is nil' do
      subject(:category) { build(:category, description: nil) }

      it :aggregate_failures do
        expect(category).to be_invalid
        expect(category.errors).to be_added(:description, :blank)
      end
    end

    context 'when is blank' do
      subject(:category) { build(:category, description: '') }

      it :aggregate_failures do
        expect(category).to be_invalid
        expect(category.errors).to be_added(:description, :blank)
      end
    end

    context 'when already taken by same user' do
      subject(:second_category) do
        build(:category,
              user: first_category.user,
              description: first_category.description)
      end

      let(:first_category) { create(:category) }

      it :aggregate_failures do
        expect(second_category).to be_invalid
        expect(second_category.errors)
          .to be_added(
            :description, :taken, { value: first_category.description }
          )
      end
    end

    context 'when already taken by same user case insensitive' do
      subject(:second_category) do
        build(:category,
              user: first_category.user,
              description: first_category.description.upcase)
      end

      let(:first_category) { create(:category) }

      it :aggregate_failures do
        expect(second_category).to be_invalid
        expect(second_category.errors)
          .to be_added(
            :description, :taken, { value: first_category.description.upcase }
          )
      end
    end

    context 'when already taken by other user' do
      subject(:second_category) do
        build(:category, description: first_category.description)
      end

      let(:first_category) { create(:category) }

      it { is_expected.to be_valid }
    end
  end

  describe '#created_at' do
    context 'when is read-only' do
      subject(:category) { create(:category) }

      it do
        expect { category.update(created_at: Time.current) && category.reload }
          .not_to change(category, :created_at)
      end
    end
  end

  describe '#to_param' do
    let(:category) { create(:category) }

    it { expect(category.to_param).to eq(category.key) }
  end

  describe '#current_budget' do
    subject(:current_budget) { category.current_budget }

    let!(:category) { create(:category) }

    context 'without any budget' do
      it { is_expected.to be_nil }
    end

    context 'with an outdated budget' do
      before { create(:budget, category:) }

      it do
        travel_to(1.month.from_now) { expect(current_budget).to be_nil }
      end
    end

    context 'with current budget' do
      let(:budget) do
        build(:budget, category:, ends_at: Date.current + 1.month)
      end

      before { budget.save }

      it do
        travel_to(1.month.from_now) { expect(current_budget).to eq(budget) }
      end
    end

    context 'with endless budget' do
      let(:budget) { build(:budget, category:, ends_at: nil) }

      before { budget.save }

      it do
        travel_to(1.month.from_now) { expect(current_budget).to eq(budget) }
      end
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

    context 'when date is nil' do
      let(:date) { nil }

      it { is_expected.to be_nil }
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
      let!(:payment) { create(:payment, :categorized) }
      let(:category) { payment.category }

      it { expect { category.destroy }.not_to change(Payment, :count) }

      it do
        expect { category.destroy }.to change { payment.reload.category }
          .from(category).to(nil)
      end
    end
  end
end
