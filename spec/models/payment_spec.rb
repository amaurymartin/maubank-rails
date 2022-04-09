# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe '#validate' do
    subject(:payment) { build(:payment) }

    it { is_expected.to be_valid }
  end

  describe '#user' do
    subject(:payment) { build(:payment, wallet:) }

    let(:wallet) { build(:wallet) }

    it { expect(payment.user).to be wallet.user }
  end

  describe '#category' do
    context "when does belongs to wallet's user" do
      subject(:payment) { build(:payment, :categorized) }

      it { is_expected.to be_valid }
    end

    context "when does not belongs to wallet's user" do
      subject(:payment) do
        build(:payment, wallet:, category: create(:category))
      end

      let(:wallet) { create(:wallet) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#wallet' do
    context 'when is nil' do
      subject(:payment) { build(:payment, wallet: nil) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#key' do
    context 'when is nil' do
      subject(:payment) { build(:payment, key: nil) }

      it :aggregate_failures do
        expect(payment).to be_valid
        expect(payment.key).to be_present
      end
    end

    context 'when is blank' do
      subject(:payment) { build(:payment, key: '') }

      it :aggregate_failures do
        expect(payment).to be_valid
        expect(payment.key).to be_present
      end
    end

    context 'when is invalid' do
      subject(:payment) { build(:payment, key: invalid_key) }

      let(:invalid_key) { 'invalid_key' }

      it :aggregate_failures do
        expect(payment).to be_valid
        expect(payment.key).not_to eq(invalid_key)
      end
    end

    context 'when already taken' do
      subject(:second_payment) { build(:payment, key: first_payment.key) }

      let(:first_payment) { create(:payment) }

      it { is_expected.to be_invalid }
    end

    context 'when is read-only' do
      subject(:payment) { create(:payment) }

      it do
        expect { payment.update(key: SecureRandom.uuid) && payment.reload }
          .not_to change(payment, :key)
      end
    end
  end

  describe '#effective_date' do
    context 'when is nil' do
      subject(:payment) { build(:payment, effective_date: nil) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#amount' do
    context 'when is nil' do
      subject(:payment) { build(:payment, amount: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when is less than -999_999_999.99' do
      subject(:payment) { build(:payment, amount: -1_000_000_000.00) }

      it { is_expected.to be_invalid }
    end

    context 'when is equal to -999_999_999.99' do
      subject(:payment) { build(:payment, amount: -999_999_999.99) }

      it { is_expected.to be_valid }
    end

    context 'when is equal to zero' do
      subject(:payment) { build(:payment, amount: 0.00) }

      it { is_expected.to be_invalid }
    end

    context 'when is equal to 999_999_999.99' do
      subject(:payment) { build(:payment, amount: 999_999_999.99) }

      it { is_expected.to be_valid }
    end

    context 'when is greater than 999_999_999.99' do
      subject(:payment) { build(:payment, amount: 1_000_000_000.00) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#created_at' do
    context 'when is read-only' do
      subject(:payment) { create(:payment) }

      it do
        expect { payment.update(created_at: Time.current) && payment.reload }
          .not_to change(payment, :created_at)
      end
    end
  end

  describe '#update_wallet_balance' do
    describe 'on_create' do
      let(:payment) { build(:payment, amount:) }

      before do
        allow(payment).to receive(:update_wallet_balance)
        payment.save
      end

      context "when new payment's amount is negative" do
        let(:amount) { -4.20 }

        it { expect(payment).to have_received(:update_wallet_balance) }
      end

      context "when new payment's amount is zero" do
        let(:amount) { 0 }

        it { expect(payment).not_to have_received(:update_wallet_balance) }
      end

      context "when new payment's amount is positive" do
        let(:amount) { 4.20 }

        it { expect(payment).to have_received(:update_wallet_balance) }
      end
    end

    describe 'on_update' do
      let(:payment) { create(:payment, amount: 4.20) }

      before do
        allow(payment).to receive(:update_wallet_balance)
      end

      context "when new payment's amount is negative" do
        before { payment.update(amount: -4.20) }

        it { expect(payment).to have_received(:update_wallet_balance) }
      end

      context "when new payment's amount is zero" do
        before { payment.update(amount: 0) }

        it { expect(payment).not_to have_received(:update_wallet_balance) }
      end

      context "when new payment's amount is positive" do
        before { payment.update(amount: 420) }

        it { expect(payment).to have_received(:update_wallet_balance) }
      end

      context "when new payment's amount is the same" do
        before { payment.update(amount: payment.amount) }

        it { expect(payment).not_to have_received(:update_wallet_balance) }
      end

      context "when new payment's amount is not changed" do
        before { payment.update(category: nil) }

        it { expect(payment).not_to have_received(:update_wallet_balance) }
      end
    end
  end
end
