# frozen_string_literal: true

# == Schema Information
#
# Table name: goals
#
#  id          :bigint           not null, primary key
#  amount      :decimal(11, 2)   not null
#  description :text             not null
#  ends_at     :date             not null
#  key         :uuid             not null
#  starts_at   :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_goals_on_key                      (key) UNIQUE
#  index_goals_on_user_id                  (user_id)
#  index_goals_on_user_id_and_description  (user_id,description) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Goal do
  describe '#validate' do
    subject(:goal) { build(:goal) }

    it { is_expected.to be_valid }
  end

  describe '#user' do
    context 'when is nil' do
      subject(:goal) { build(:goal, user: nil) }

      it :aggregate_failures do
        expect(goal).not_to be_valid
        expect(goal.errors).to be_added(:user, :blank)
      end
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

      it 'must auto generate', :aggregate_failures do
        expect(goal).to be_valid
        expect(goal.key).to be_present
      end
    end

    context 'when is blank' do
      subject(:goal) { build(:goal, key: '') }

      it 'must auto generate', :aggregate_failures do
        expect(goal).to be_valid
        expect(goal.key).to be_present
      end
    end

    context 'when is invalid' do
      subject(:goal) { build(:goal, key: invalid_key) }

      let(:invalid_key) { 'invalid_key' }

      it 'must auto generate', :aggregate_failures do
        expect(goal).to be_valid
        expect(goal.key).not_to eq(invalid_key)
      end
    end

    context 'when already taken' do
      subject(:second_goal) { build(:goal, key: first_goal.key) }

      let(:first_goal) { create(:goal) }

      it :aggregate_failures do
        expect(second_goal).not_to be_valid
        expect(second_goal.errors)
          .to be_added(:key, :taken, { value: first_goal.key })
      end
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

      it :aggregate_failures do
        expect(goal).not_to be_valid
        expect(goal.errors).to be_added(:description, :blank)
      end
    end

    context 'when is blank' do
      subject(:goal) { build(:goal, description: '') }

      it :aggregate_failures do
        expect(goal).not_to be_valid
        expect(goal.errors).to be_added(:description, :blank)
      end
    end

    context 'when already taken by same user' do
      subject(:second_goal) do
        build(:goal,
              user: first_goal.user,
              description: first_goal.description)
      end

      let(:first_goal) { create(:goal) }

      it :aggregate_failures do
        expect(second_goal).not_to be_valid
        expect(second_goal.errors)
          .to be_added(:description, :taken, { value: first_goal.description })
      end
    end

    context 'when already taken by same user case insensitive' do
      subject(:second_goal) do
        build(:goal,
              user: first_goal.user,
              description: first_goal.description.upcase)
      end

      let(:first_goal) { create(:goal) }

      it 'must be case insensitive', :aggregate_failures do
        expect(second_goal).not_to be_valid
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

      it :aggregate_failures do
        expect(goal).not_to be_valid
        expect(goal.errors).to be_added(:amount, :not_a_number, value: nil)
      end
    end

    context 'when is negative' do
      subject(:goal) { build(:goal, amount: negative_amount) }

      let(:negative_amount) { -0.01 }

      it 'must be greater than zero', :aggregate_failures do
        expect(goal).not_to be_valid
        expect(goal.errors).to be_added(
          :amount, :greater_than, { value: negative_amount, count: 0.00 }
        )
      end
    end

    context 'when is equal to zero' do
      subject(:goal) { build(:goal, amount: 0.00) }

      it 'must be greater than zero', :aggregate_failures do
        expect(goal).not_to be_valid
        expect(goal.errors).to be_added(
          :amount, :greater_than, { value: 0.00, count: 0.0 }
        )
      end
    end

    context 'when is equal to 999_999_999.99' do
      subject(:goal) { build(:goal, amount: 999_999_999.99) }

      it { is_expected.to be_valid }
    end

    context 'when is greater than 999_999_999.99' do
      subject(:goal) { build(:goal, amount:) }

      let(:amount) { 1_000_000_000.00 }

      it 'must be less than 1_000_000_000.00', :aggregate_failures do
        expect(goal).not_to be_valid
        expect(goal.errors).to be_added(
          :amount, :less_than, { value: amount, count: 1_000_000_000.00 }
        )
      end
    end
  end

  describe '#starts_at' do
    context 'when is nil' do
      subject(:goal) { build(:goal, starts_at: nil) }

      it :aggregate_failures do
        expect(goal).not_to be_valid
        expect(goal.errors).to be_added(:starts_at, :blank)
      end
    end
  end

  describe '#ends_at' do
    context 'when is nil' do
      subject(:goal) { build(:goal, ends_at: nil) }

      it :aggregate_failures do
        expect(goal).not_to be_valid
        expect(goal.errors).to be_added(
          :ends_at, :blank, { value: nil, count: goal.starts_at }
        )
      end
    end

    context 'when starts_at is nil' do
      subject(:goal) { build(:goal, starts_at: nil, ends_at: Date.current) }

      it :aggregate_failures do
        expect(goal).not_to be_valid
        expect(goal.errors).to be_added(:starts_at, :blank)
        expect(goal.errors).not_to be_added(:ends_at)
      end
    end

    context 'when is before starts_at' do
      subject(:goal) do
        build(:goal, starts_at: Date.current.beginning_of_year, ends_at:)
      end

      let(:ends_at) { Date.current.beginning_of_year - 1.day }

      it :aggregate_failures do
        expect(goal).not_to be_valid
        expect(goal.errors).to be_added(
          :ends_at, :greater_than, { value: ends_at, count: goal.starts_at }
        )
      end
    end

    context 'when is equal starts_at' do
      subject(:goal) { build(:goal, ends_at: starts_at) }

      let(:starts_at) { Date.current.beginning_of_year }

      it :aggregate_failures do
        expect(goal).not_to be_valid
        expect(goal.errors).to be_added(
          :ends_at, :greater_than, { value: starts_at, count: goal.starts_at }
        )
      end
    end
  end

  describe '#created_at' do
    context 'when is read-only' do
      subject(:goal) { create(:goal) }

      it do
        expect { goal.update(created_at: Time.current) && goal.reload }
          .not_to change(goal, :created_at)
      end
    end
  end

  describe '#to_param' do
    let(:goal) { create(:goal) }

    it { expect(goal.to_param).to eq(goal.key) }
  end
end
