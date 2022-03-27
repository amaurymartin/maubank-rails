# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Goal, type: :model do
  describe '#validate' do
    subject(:goal) { build(:goal) }

    it { is_expected.to be_valid }
  end

  describe '#user' do
    context 'when is nil' do
      subject(:goal) { build(:goal, user: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when is read-only' do
      subject(:goal) { create(:goal) }

      let(:other_user) { create(:user) }

      it do
        expect { goal.update(user: other_user) && goal.reload }
          .not_to change(goal, :user)
      end
    end
  end

  describe '#key' do
    context 'when is nil' do
      subject(:goal) { build(:goal, key: nil) }

      it :aggregate_failures do
        expect(goal).to be_valid
        expect(goal.key).to be_present
      end
    end

    context 'when is blank' do
      subject(:goal) { build(:goal, key: '') }

      it :aggregate_failures do
        expect(goal).to be_valid
        expect(goal.key).to be_present
      end
    end

    context 'when is invalid' do
      subject(:goal) { build(:goal, key: invalid_key) }

      let(:invalid_key) { 'invalid_key' }

      it :aggregate_failures do
        expect(goal).to be_valid
        expect(goal.key).not_to eq(invalid_key)
      end
    end

    context 'when already taken' do
      subject(:second_goal) { build(:goal, key: first_goal.key) }

      let(:first_goal) { create(:goal) }

      it { is_expected.to be_invalid }
    end

    context 'when is read-only' do
      subject(:goal) { create(:goal) }

      it do
        expect { goal.update(key: SecureRandom.uuid) && goal.reload }
          .not_to change(goal, :key)
      end
    end
  end

  describe '#description' do
    context 'when is nil' do
      subject(:goal) { build(:goal, description: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when is blank' do
      subject(:goal) { build(:goal, description: '') }

      it { is_expected.to be_invalid }
    end

    context 'when already taken by same user' do
      subject(:second_goal) do
        build(:goal,
              user: first_goal.user,
              description: first_goal.description)
      end

      let(:first_goal) { create(:goal) }

      it { is_expected.to be_invalid }
    end

    context 'when already taken by same user case insensitive' do
      subject(:second_goal) do
        build(:goal,
              user: first_goal.user,
              description: first_goal.description.upcase)
      end

      let(:first_goal) { create(:goal) }

      it 'must be case insensitive', :aggregate_failures do
        expect(second_goal).to be_invalid
        expect(second_goal.errors).to be_added(
          :description, :taken, { value: first_goal.description.upcase }
        )
      end
    end

    context 'when already taken by other user' do
      subject(:second_goal) do
        build(:goal, description: first_goal.description)
      end

      let(:first_goal) { create(:goal) }

      it { is_expected.to be_valid }
    end
  end

  describe '#amount' do
    context 'when is nil' do
      subject(:goal) { build(:goal, amount: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when is negative' do
      subject(:goal) { build(:goal, amount: -0.01) }

      it { is_expected.to be_invalid }
    end

    context 'when is equal to zero' do
      subject(:goal) { build(:goal, amount: 0.00) }

      it { is_expected.to be_invalid }
    end

    context 'when is equal to 999_999_999.99' do
      subject(:goal) { build(:goal, amount: 999_999_999.99) }

      it { is_expected.to be_valid }
    end

    context 'when is greater than 999_999_999.99' do
      subject(:goal) { build(:goal, amount: 1_000_000_000.00) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#starts_at' do
    context 'when is nil' do
      subject(:goal) { build(:goal, starts_at: nil) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#ends_at' do
    context 'when is nil' do
      subject(:goal) { build(:goal, ends_at: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when is before starts_at' do
      subject(:goal) { build(:goal, ends_at: starts_at - 1.day) }

      let(:starts_at) { Date.current.beginning_of_year }

      it { is_expected.to be_invalid }
    end

    context 'when is equal starts_at' do
      subject(:goal) { build(:goal, ends_at: starts_at) }

      let(:starts_at) { Date.current.beginning_of_year }

      it { is_expected.to be_invalid }
    end
  end
end
