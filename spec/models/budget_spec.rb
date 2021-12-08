# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Budget, type: :model do
  subject(:budget) { build(:budget) }

  before { budget.validate }

  describe '#validate' do
    it { is_expected.to be_valid }
  end

  describe '#user' do
    subject(:budget) { build(:budget, category: category) }

    let(:category) { build(:category) }

    it { expect(budget.user).to be category.user }
  end

  describe '#category' do
    context 'when is nil' do
      subject(:budget) { build(:budget, category: nil) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#key' do
    context 'when is nil' do
      subject(:budget) { build(:budget, key: nil) }

      it :aggregate_failures do
        expect(budget).to be_valid
        expect(budget.key).to be_present
      end
    end

    context 'when is blank' do
      subject(:budget) { build(:budget, key: '') }

      it :aggregate_failures do
        expect(budget).to be_valid
        expect(budget.key).to be_present
      end
    end

    context 'when is invalid' do
      subject(:budget) { build(:budget, key: invalid_key) }

      let(:invalid_key) { 'invalid_key' }

      it :aggregate_failures do
        expect(budget).to be_valid
        expect(budget.key).not_to eq(invalid_key)
      end
    end

    context 'when already taken' do
      subject(:second_budget) { build(:budget, key: first_budget.key) }

      let(:first_budget) { create(:budget) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#amount' do
    context 'when is nil' do
      subject(:budget) { build(:budget, amount: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when is negative' do
      subject(:budget) { build(:budget, amount: -0.01) }

      it { is_expected.to be_invalid }
    end

    context 'when is equal to zero' do
      subject(:budget) { build(:budget, amount: 0.00) }

      it { is_expected.to be_invalid }
    end

    context 'when is equal to 999_999_999.99' do
      subject(:budget) { build(:budget, amount: 999_999_999.99) }

      it { is_expected.to be_valid }
    end

    context 'when is greater than 999_999_999.99' do
      subject(:budget) { build(:budget, amount: 1_000_000_000.00) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#starts_at' do
    context 'when is nil' do
      subject(:budget) { build(:budget, starts_at: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when is already taken by same category' do
      subject(:second_budget) do
        build(:budget,
              category: first_budget.category,
              starts_at: first_budget.starts_at)
      end

      let(:first_budget) { create(:budget) }

      it { is_expected.to be_invalid }
    end

    context 'when is already taken by other category' do
      subject(:second_budget) do
        build(:budget, starts_at: first_budget.starts_at)
      end

      let(:first_budget) { create(:budget) }

      it { is_expected.to be_valid }
    end

    context 'when is not beginning of month' do
      subject(:budget) { build(:budget, starts_at: invalid_starts_at) }

      let(:invalid_starts_at) { Date.current.beginning_of_month + 1.day }

      it 'must set to beginning of month', :aggregate_failures do
        expect(budget).to be_valid
        expect(budget.starts_at).to eq(invalid_starts_at.beginning_of_month)
      end
    end

    context 'when is beginning of past month' do
      subject(:budget) do
        build(:budget, starts_at: Date.current.beginning_of_month - 1.month)
      end

      it { is_expected.to be_invalid }
    end

    context 'when is beginning of current month' do
      subject(:budget) do
        build(:budget, starts_at: Date.current.beginning_of_month)
      end

      it { is_expected.to be_valid }
    end

    context 'when is beginning of a future month' do
      subject(:budget) do
        build(:budget, starts_at: Date.current.beginning_of_month + 1.month)
      end

      it { is_expected.to be_valid }
    end
  end

  describe '#ends_at' do
    context 'when is nil' do
      subject(:budget) { build(:budget, ends_at: nil) }

      it { is_expected.to be_valid }
    end

    context 'when nil is already taken by same category - postdate' do
      subject(:second_budget) do
        build(:budget,
              category: first_budget.category,
              starts_at: first_budget.starts_at + 1.month,
              ends_at: nil)
      end

      let(:first_budget) { create(:budget, ends_at: nil) }

      it 'must updates first_budget ends_at', :aggregate_failures do
        expect(second_budget).to be_valid
        expect(first_budget.reload.ends_at)
          .to eq(second_budget.starts_at - 1.day)
      end
    end

    context 'when nil is already taken by same category - backdate' do
      subject(:second_budget) do
        build(:budget,
              category: first_budget.category,
              starts_at: Date.current,
              ends_at: nil)
      end

      let(:first_budget) do
        create(:budget, starts_at: Date.current + 1.month, ends_at: nil)
      end

      it 'must updates first_budget ends_at', :aggregate_failures do
        expect(second_budget).to be_valid
        expect(first_budget.reload.ends_at)
          .to eq(first_budget.starts_at.end_of_month)
      end
    end

    context 'when nil is already taken by other category' do
      subject(:second_budget) do
        build(:budget,
              starts_at: first_budget.starts_at + 1.month,
              ends_at: nil)
      end

      let(:first_budget) { create(:budget) }

      it { is_expected.to be_valid }
    end

    context 'when date is already taken by same category' do
      subject(:second_budget) do
        build(:budget,
              category: first_budget.category,
              ends_at: first_budget.ends_at)
      end

      let(:first_budget) { create(:budget) }

      it { is_expected.to be_invalid }
    end

    context 'when date is already taken by other category' do
      subject(:second_budget) { build(:budget, ends_at: first_budget.ends_at) }

      let(:first_budget) { create(:budget) }

      it { is_expected.to be_valid }
    end

    context 'when is not end of month' do
      subject(:budget) { build(:budget, ends_at: invalid_ends_at) }

      let(:invalid_ends_at) { Date.current.end_of_month - 1.day }

      it 'must set to end of month', :aggregate_failures do
        expect(budget).to be_valid
        expect(budget.ends_at).to eq(invalid_ends_at.end_of_month)
      end
    end

    context 'when is end of past month' do
      subject(:budget) do
        build(:budget, ends_at: Date.current.end_of_month - 1.month)
      end

      it { is_expected.to be_invalid }
    end

    context 'when is end of current month' do
      subject(:budget) { build(:budget, ends_at: Date.current.end_of_month) }

      it { is_expected.to be_valid }
    end

    context 'when is end of a future month' do
      subject(:budget) do
        build(:budget, ends_at: (Date.current + 1.month).end_of_month)
      end

      it { is_expected.to be_valid }
    end
  end
end
