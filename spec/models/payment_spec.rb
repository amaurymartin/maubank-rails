# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe '#validate' do
    subject(:payment) { build(:payment) }

    it { is_expected.to be_valid }
  end

  describe '#user' do
    subject(:payment) { build(:payment, wallet: wallet) }

    let(:wallet) { build(:wallet) }

    it { expect(payment.user).to be wallet.user }
  end

  describe '#category' do
    context 'when is nil' do
      subject(:payment) { build(:payment, :uncategorized) }

      it { is_expected.to be_valid }
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
end
