# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Budget, type: :model do
  describe '#validate' do
    subject(:budget) { build(:budget) }

    it { is_expected.to be_valid }
  end

  describe '#user' do
    subject(:budget) { build(:budget, category:) }

    let(:category) { build(:category) }

    it { expect(budget.user).to be category.user }
  end

  describe '#category' do
    context 'when is nil' do
      subject(:budget) { build(:budget, category: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when is read-only' do
      subject(:budget) { create(:budget) }

      let(:other_category) { create(:category) }

      it do
        expect { budget.update(category: other_category) && budget.reload }
          .not_to change(budget, :category)
      end
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

    context 'when is read-only' do
      subject(:budget) { create(:budget) }

      it do
        expect { budget.update(key: SecureRandom.uuid) && budget.reload }
          .not_to change(budget, :key)
      end
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

    context 'when already taken by same category' do
      subject(:second_budget) do
        build(:budget,
              category: first_budget.category,
              starts_at: first_budget.starts_at)
      end

      let(:first_budget) { create(:budget) }

      it { is_expected.to be_invalid }
    end

    context 'when already taken by other category' do
      subject(:second_budget) do
        build(:budget, starts_at: first_budget.starts_at)
      end

      let(:first_budget) { create(:budget) }

      it { is_expected.to be_valid }
    end

    context 'when is not beginning of month' do
      subject(:budget) { build(:budget, starts_at:) }

      let(:starts_at) { Date.current.beginning_of_month + 1.day }

      it 'must be set to beginning of month', :aggregate_failures do
        expect(budget).to be_valid
        expect(budget.starts_at).to eq(starts_at.beginning_of_month)
      end
    end

    context 'when is in the past' do
      subject(:budget) { build(:budget, starts_at: Date.current - 1.month) }

      it { is_expected.to be_invalid }
    end

    context 'when is in current month' do
      subject(:budget) { build(:budget, starts_at: Date.current) }

      it { is_expected.to be_valid }
    end

    context 'when is in the future' do
      subject(:budget) { build(:budget, starts_at: Date.current + 1.month) }

      it { is_expected.to be_valid }
    end
  end

  describe '#ends_at' do
    context 'when is nil' do
      subject(:budget) { build(:budget, ends_at: nil) }

      it { is_expected.to be_valid }
    end

    context 'when nil is already taken by same category - present' do
      subject(:second_budget) do
        build(:budget,
              category: first_budget.category,
              starts_at: Date.current,
              ends_at: nil)
      end

      let(:first_budget) do
        create(:budget, starts_at: Date.current + 1.month, ends_at: nil)
      end

      it 'must updates prior endless budget ends_at', :aggregate_failures do
        expect(second_budget).to be_valid
        expect { second_budget.save }.to change { first_budget.reload.ends_at }
          .from(nil).to(first_budget.starts_at.end_of_month)
      end
    end

    context 'when nil is already taken by same category - future' do
      subject(:second_budget) do
        build(:budget,
              category: first_budget.category,
              starts_at: first_budget.starts_at + 1.month,
              ends_at: nil)
      end

      let(:first_budget) { create(:budget, ends_at: nil) }

      it 'must updates prior endless budget ends_at', :aggregate_failures do
        expect(second_budget).to be_valid
        expect { second_budget.save }.to change { first_budget.reload.ends_at }
          .from(nil).to(second_budget.starts_at - 1.day)
      end
    end

    context 'when nil is already taken by other category' do
      subject(:second_budget) do
        build(:budget,
              starts_at: first_budget.starts_at + 1.month,
              ends_at: nil)
      end

      let(:first_budget) { create(:budget, ends_at: nil) }

      it 'must not update other category endless budget', :aggregate_failures do
        expect(second_budget).to be_valid
        expect { second_budget.save }.not_to change(first_budget, :ends_at)
      end
    end

    context 'when date is already taken by same category' do
      subject(:second_budget) do
        build(:budget,
              category: first_budget.category,
              starts_at: first_budget.starts_at - 1.month,
              ends_at: first_budget.ends_at)
      end

      let(:first_budget) { create(:budget, starts_at: Date.current + 1.month) }

      it { is_expected.to be_invalid }
    end

    context 'when date is already taken by other category' do
      subject(:second_budget) do
        build(:budget,
              starts_at: first_budget.starts_at,
              ends_at: first_budget.ends_at)
      end

      let(:first_budget) { create(:budget) }

      it { is_expected.to be_valid }
    end

    context 'when is not end of month' do
      subject(:budget) { build(:budget, starts_at: Date.current, ends_at:) }

      let(:ends_at) { Date.current.end_of_month - 1.day }

      it 'must be set to end of month', :aggregate_failures do
        expect(budget).to be_valid
        expect(budget.ends_at).to eq(ends_at.end_of_month)
      end
    end

    context 'when is in the past' do
      subject(:budget) do
        build(:budget,
              starts_at: Date.current - 1.month,
              ends_at: Date.current - 1.month)
      end

      it { is_expected.to be_invalid }
    end

    context 'when is in current month' do
      subject(:budget) do
        build(:budget, starts_at: Date.current, ends_at: Date.current)
      end

      it { is_expected.to be_valid }
    end

    context 'when is in the future' do
      subject(:budget) do
        build(:budget,
              starts_at: Date.current + 1.month,
              ends_at: Date.current + 1.month)
      end

      it { is_expected.to be_valid }
    end

    context 'when is not in the same month as starts_at - present' do
      subject(:budget) do
        build(:budget, starts_at: Date.current, ends_at: Date.current + 1.month)
      end

      it { is_expected.to be_valid }
    end

    context 'when is not in the same month as starts_at - future' do
      subject(:budget) do
        build(:budget,
              starts_at: Date.current + 1.month,
              ends_at: Date.current + 2.months)
      end

      it { is_expected.to be_valid }
    end
  end

  describe 'scopes' do
    describe '.endless_for' do
      subject(:endless_budget_for_category) do
        described_class.endless_for(category)
      end

      let!(:endless_budget) { create(:budget, category:, ends_at:) }
      let(:category) { create(:category) }
      let(:ends_at) { nil }

      context 'without endless budget for category' do
        let(:ends_at) { Date.current }

        it { is_expected.to be_empty }
      end

      context 'with a uniq endless budget for category' do
        it 'must return endless budget', :aggregate_failures do
          expect(endless_budget_for_category.first).to eq(endless_budget)
          expect(endless_budget_for_category.count).to eq(1)
        end
      end

      context 'with more than one endless budget for category' do
        let(:other_endless_budget) do
          build(:budget,
                key: SecureRandom.uuid,
                starts_at: Date.current.beginning_of_month + 1.month,
                category:,
                ends_at:)
        end

        before do
          # rubocop:disable RSpec/AnyInstance
          allow_any_instance_of(described_class)
            .to receive(:update_endless_budgets).and_return(nil)
          # rubocop:enable RSpec/AnyInstance

          other_endless_budget.save
        end

        it 'must return all endless budgets ordered', :aggregate_failures do
          expect(endless_budget_for_category.count).to eq(2)
          expect(endless_budget_for_category.first).to eq(endless_budget)
          expect(endless_budget_for_category.second).to eq(other_endless_budget)
        end
      end

      context 'with endless budget for another category' do
        subject(:endless_budget_for_category) do
          described_class.endless_for(create(:category))
        end

        it { is_expected.to be_empty }
      end
    end

    describe '.for' do
      subject(:budgets_for_date) { described_class.for(date) }

      let(:ends_at) { nil }
      let!(:first_budget) { create(:budget, ends_at:) }
      let!(:second_budget) do
        create(
          :budget,
          starts_at: Date.current + 1.month,
          ends_at: Date.current + 1.month
        )
      end

      context 'when date is in the past and no budget was found' do
        let(:date) { Date.current - 1.month }

        it { is_expected.to be_empty }
      end

      context 'when date is in the future and no budget was found' do
        let(:date) { Date.current + 2.months }
        let(:ends_at) { Date.current }

        it { is_expected.to be_empty }
      end

      context 'when date is in the future and endless budget exists' do
        let(:date) { Date.current + 2.months }

        it 'must return only one endless budget', :aggregate_failures do
          expect(budgets_for_date.count).to eq(1)
          expect(budgets_for_date.first).to eq(first_budget)
        end
      end

      context "when date is within endless budget starts_at's month" do
        let(:date) { Date.current }

        it 'must return only one endless budget', :aggregate_failures do
          expect(budgets_for_date.count).to eq(1)
          expect(budgets_for_date.first).to eq(first_budget)
        end
      end

      context 'with specific budget for the date' do
        let(:date) { Date.current + 1.month }

        it 'must return only one budget', :aggregate_failures do
          expect(budgets_for_date.count).to eq(1)
          expect(budgets_for_date.first).to eq(second_budget)
        end
      end
    end
  end
end
