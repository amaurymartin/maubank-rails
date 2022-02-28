# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wallet, type: :model do
  describe '#validate' do
    subject(:wallet) { build(:wallet) }

    it { is_expected.to be_valid }
  end

  describe '#user' do
    context 'when is nil' do
      subject(:wallet) { build(:wallet, user: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when updating' do
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

      it :aggregate_failures do
        expect(wallet).to be_valid
        expect(wallet.key).to be_present
      end
    end

    context 'when is blank' do
      subject(:wallet) { build(:wallet, key: '') }

      it :aggregate_failures do
        expect(wallet).to be_valid
        expect(wallet.key).to be_present
      end
    end

    context 'when is invalid' do
      subject(:wallet) { build(:wallet, key: invalid_key) }

      let(:invalid_key) { 'invalid_key' }

      it :aggregate_failures do
        expect(wallet).to be_valid
        expect(wallet.key).not_to eq(invalid_key)
      end
    end

    context 'when already taken' do
      subject(:second_wallet) { build(:wallet, key: first_wallet.key) }

      let(:first_wallet) { create(:wallet) }

      it { is_expected.to be_invalid }
    end

    context 'when updating' do
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

      it { is_expected.to be_invalid }
    end

    context 'when is blank' do
      subject(:wallet) { build(:wallet, description: '') }

      it { is_expected.to be_invalid }
    end

    context 'when is already taken by same user' do
      subject(:second_wallet) do
        build(:wallet,
              user: first_wallet.user,
              description: first_wallet.description)
      end

      let(:first_wallet) { create(:wallet) }

      it { is_expected.to be_invalid }
    end

    context 'when is already taken by same user case insensitive' do
      subject(:second_wallet) do
        build(:wallet,
              user: first_wallet.user,
              description: first_wallet.description.upcase)
      end

      let(:first_wallet) { create(:wallet) }

      it { is_expected.to be_invalid }
    end

    context 'when is already taken by other user' do
      subject(:second_wallet) do
        build(:wallet, description: first_wallet.description)
      end

      let(:first_wallet) { create(:wallet) }

      it { is_expected.to be_valid }
    end
  end

  describe 'dependent destroy' do
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
