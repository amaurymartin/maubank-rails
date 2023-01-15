# frozen_string_literal: true

# == Schema Information
#
# Table name: wallets
#
#  id          :bigint           not null, primary key
#  balance     :decimal(11, 2)   not null
#  description :text             not null
#  key         :uuid             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_wallets_on_key                      (key) UNIQUE
#  index_wallets_on_user_id                  (user_id)
#  index_wallets_on_user_id_and_description  (user_id,description) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Wallet do
  describe '#validate' do
    subject(:wallet) { build(:wallet) }

    it { is_expected.to be_valid }
  end

  describe '#user' do
    context 'when is nil' do
      subject(:wallet) { build(:wallet, user: nil) }

      it :aggregate_failures do
        expect(wallet).to be_invalid
        expect(wallet.errors).to be_added(:user, :blank)
      end
    end

    context 'when is read-only' do
      subject(:wallet) { create(:wallet) }

      let(:other_user) { create(:user) }

      it do
        expect { wallet.update(user: other_user) && wallet.reload }
          .not_to change(wallet, :user)
      end
    end
  end

  describe '#key' do
    context 'when is nil' do
      subject(:wallet) { build(:wallet, key: nil) }

      it 'must auto generate', :aggregate_failures do
        expect(wallet).to be_valid
        expect(wallet.key).to be_present
      end
    end

    context 'when is blank' do
      subject(:wallet) { build(:wallet, key: '') }

      it 'must auto generate', :aggregate_failures do
        expect(wallet).to be_valid
        expect(wallet.key).to be_present
      end
    end

    context 'when is invalid' do
      subject(:wallet) { build(:wallet, key: invalid_key) }

      let(:invalid_key) { 'invalid_key' }

      it 'must auto generate', :aggregate_failures do
        expect(wallet).to be_valid
        expect(wallet.key).not_to eq(invalid_key)
      end
    end

    context 'when already taken' do
      subject(:second_wallet) { build(:wallet, key: first_wallet.key) }

      let(:first_wallet) { create(:wallet) }

      it :aggregate_failures do
        expect(second_wallet).to be_invalid
        expect(second_wallet.errors)
          .to be_added(:key, :taken, { value: first_wallet.key })
      end
    end

    context 'when is read-only' do
      subject(:wallet) { create(:wallet) }

      it do
        expect { wallet.update(key: SecureRandom.uuid) && wallet.reload }
          .not_to change(wallet, :key)
      end
    end
  end

  describe '#description' do
    context 'when is nil' do
      subject(:wallet) { build(:wallet, description: nil) }

      it :aggregate_failures do
        expect(wallet).to be_invalid
        expect(wallet.errors).to be_added(:description, :blank)
      end
    end

    context 'when is blank' do
      subject(:wallet) { build(:wallet, description: '') }

      it :aggregate_failures do
        expect(wallet).to be_invalid
        expect(wallet.errors).to be_added(:description, :blank)
      end
    end

    context 'when already taken by same user' do
      subject(:second_wallet) do
        build(:wallet,
              user: first_wallet.user,
              description: first_wallet.description)
      end

      let(:first_wallet) { create(:wallet) }

      it :aggregate_failures do
        expect(second_wallet).to be_invalid
        expect(second_wallet.errors).to be_added(
          :description, :taken, { value: first_wallet.description }
        )
      end
    end

    context 'when already taken by same user case insensitive' do
      subject(:second_wallet) do
        build(:wallet,
              user: first_wallet.user,
              description: first_wallet.description.upcase)
      end

      let(:first_wallet) { create(:wallet) }

      it 'must be case insensitive', :aggregate_failures do
        expect(second_wallet).to be_invalid
        expect(second_wallet.errors).to be_added(
          :description, :taken, { value: first_wallet.description.upcase }
        )
      end
    end

    context 'when already taken by other user' do
      subject(:second_wallet) do
        build(:wallet, description: first_wallet.description)
      end

      let(:first_wallet) { create(:wallet) }

      it { is_expected.to be_valid }
    end
  end

  describe '#balance' do
    context 'when is nil' do
      subject(:wallet) { build(:wallet, balance: nil) }

      it :aggregate_failures do
        expect(wallet).to be_invalid
        expect(wallet.errors).to be_added(:balance, :not_a_number, value: nil)
      end
    end

    context 'when is less than -999_999_999.99' do
      subject(:wallet) { build(:wallet, balance:) }

      let(:balance) { -1_000_000_000.00 }

      it 'must be greater than -1_000_000_000.00', :aggregate_failures do
        expect(wallet).to be_invalid
        expect(wallet.errors).to be_added(
          :balance, :greater_than, { value: balance, count: -1_000_000_000.00 }
        )
      end
    end

    context 'when is equal to -999_999_999.99' do
      subject(:wallet) { build(:wallet, balance: -999_999_999.99) }

      it { is_expected.to be_valid }
    end

    context 'when is equal to zero' do
      subject(:wallet) { build(:wallet, balance: 0.00) }

      it { is_expected.to be_valid }
    end

    context 'when is equal to 999_999_999.99' do
      subject(:wallet) { build(:wallet, balance: 999_999_999.99) }

      it { is_expected.to be_valid }
    end

    context 'when is greater than 999_999_999.99' do
      subject(:wallet) { build(:wallet, balance:) }

      let(:balance) { 1_000_000_000.00 }

      it 'must be less than 1_000_000_000.00', :aggregate_failures do
        expect(wallet).to be_invalid
        expect(wallet.errors).to be_added(
          :balance, :less_than, { value: balance, count: 1_000_000_000.00 }
        )
      end
    end
  end

  describe '#created_at' do
    context 'when is read-only' do
      subject(:wallet) { create(:wallet) }

      it do
        expect { wallet.update(created_at: Time.current) && wallet.reload }
          .not_to change(wallet, :created_at)
      end
    end
  end

  describe '#to_param' do
    let(:wallet) { create(:wallet) }

    it { expect(wallet.to_param).to eq(wallet.key) }
  end

  describe '#update_balance' do
    subject(:wallet) { create(:wallet) }

    context 'when amount is nil' do
      it do
        expect { wallet.update_balance(nil) }
          .to(not_change { wallet.reload.balance }
            .and(not_change { wallet.reload.updated_at }))
      end
    end

    context 'when amount is not a number' do
      it do
        expect { wallet.update_balance('not_a_number') }
          .to(not_change { wallet.reload.balance }
            .and(not_change { wallet.reload.updated_at }))
      end
    end

    context 'when amount is zero' do
      it do
        expect { wallet.update_balance(0.00) }
          .to(not_change { wallet.reload.balance }
            .and(not_change { wallet.reload.updated_at }))
      end
    end

    context 'when new balance is less than -999_999_999.99' do
      it do
        expect { wallet.update_balance(-1_000_000_000.00 - wallet.balance) }
          .to(not_change { wallet.reload.balance }
            .and(not_change { wallet.reload.updated_at }))
      end
    end

    context 'when new balance is equal to -999_999_999.99' do
      it do
        expect { wallet.update_balance(-999_999_999.99 - wallet.balance) }
          .to(change { wallet.reload.balance }
            .and(change { wallet.reload.updated_at }))
      end
    end

    context 'when new balance is equal to zero' do
      it do
        expect { wallet.update_balance(0.00 - wallet.balance) }
          .to(change { wallet.reload.balance }
            .and(change { wallet.reload.updated_at }))
      end
    end

    context 'when new balance is equal to 999_999_999.99' do
      it do
        expect { wallet.update_balance(999_999_999.99 - wallet.balance) }
          .to(change { wallet.reload.balance }
            .and(change { wallet.reload.updated_at }))
      end
    end

    context 'when new balance is greater than 999_999_999.99' do
      it do
        expect { wallet.update_balance(1_000_000_000.00 - wallet.balance) }
          .to(not_change { wallet.reload.balance }
            .and(not_change { wallet.reload.updated_at }))
      end
    end
  end

  describe 'dependent delete_all' do
    context 'with payment' do
      let(:wallet) { create(:wallet, :with_payment) }
      let(:wallet_payments) { wallet.payments }

      it do
        expect { wallet.destroy }.to change(Payment, :count)
          .by(-wallet_payments.size)
      end
    end
  end
end
