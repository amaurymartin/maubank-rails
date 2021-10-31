# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  before { user.validate }

  describe '#validate' do
    it { is_expected.to be_valid }
  end

  describe '#key' do
    context 'when is nil' do
      subject(:user) { build(:user, key: nil) }

      it :aggregate_failures do
        expect(user).to be_valid
        expect(user.key).to be_present
      end
    end

    context 'when is blank' do
      subject(:user) { build(:user, key: '') }

      it :aggregate_failures do
        expect(user).to be_valid
        expect(user.key).to be_present
      end
    end

    context 'when is invalid' do
      subject(:user) { build(:user, key: invalid_key) }

      let(:invalid_key) { 'invalid_key' }

      it :aggregate_failures do
        expect(user).to be_valid
        expect(user.key).not_to eq(invalid_key)
      end
    end

    context 'when already taken' do
      subject(:second_user) { build(:user, key: first_user.key) }

      let!(:first_user) { create(:user) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#full_name' do
    context 'when is nil' do
      subject(:user) { build(:user, full_name: nil) }

      it { is_expected.to be_valid }
    end

    context 'when is blank' do
      subject(:user) { build(:user, full_name: '') }

      it { is_expected.to be_invalid }
    end
  end

  describe '#nickname' do
    context 'when is nil' do
      subject(:user) { build(:user, nickname: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when is blank' do
      subject(:user) { build(:user, nickname: '') }

      it { is_expected.to be_invalid }
    end
  end

  describe '#username' do
    context 'when is nil' do
      subject(:user) { build(:user, username: nil) }

      it { is_expected.to be_valid }
    end

    context 'when is blank' do
      subject(:user) { build(:user, username: '') }

      it { is_expected.to be_invalid }
    end

    context 'when nil one was already taken' do
      subject(:second_user) { build(:user, username: nil) }

      before { create(:user, username: nil) }

      it { is_expected.to be_valid }
    end

    context 'when valid one was already taken' do
      subject(:second_user) { build(:user, username: first_user.username) }

      let!(:first_user) { create(:user) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#email' do
    context 'when is nil' do
      subject(:user) { build(:user, email: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when is blank' do
      subject(:user) { build(:user, email: '') }

      it { is_expected.to be_invalid }
    end

    context 'when is invalid' do
      subject(:user) { build(:user, email: 'not_a_valid_email') }

      it { is_expected.to be_invalid }
    end

    context 'when already taken' do
      subject(:second_user) { build(:user, email: first_user.email) }

      let!(:first_user) { create(:user) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#password' do
    context 'when is nil' do
      subject(:user) { build(:user, password: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when is blank' do
      subject(:user) { build(:user, password: '') }

      it { is_expected.to be_invalid }
    end

    context 'when has less than 8 characters' do
      subject(:user) { build(:user, password: 'short') }

      it { is_expected.to be_invalid }
    end
  end

  describe '#password_confirmation' do
    context 'when is nil' do
      subject(:user) { build(:user, password_confirmation: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when is blank' do
      subject(:user) { build(:user, password_confirmation: '') }

      it { is_expected.to be_invalid }
    end

    context 'when is not equal to password' do
      subject(:user) { build(:user, password_confirmation: 'different') }

      it { is_expected.to be_invalid }
    end
  end

  describe '#documentation' do
    context 'when is nil' do
      subject(:user) { build(:user, documentation: nil) }

      it { is_expected.to be_valid }
    end

    context 'when is blank' do
      subject(:user) { build(:user, documentation: '') }

      it { is_expected.to be_invalid }
    end

    context 'when is not a brazilian CPF' do
      subject(:user) { build(:user, documentation: 'invalid') }

      it { is_expected.to be_invalid }
    end

    context 'when is not a brazilian CPF but allows other values' do
      subject(:user) { build(:user, documentation: 'invalid') }

      before { ENV['ACCEPTS_ONLY_BRAZILIAN_CPF'] = 'false' }

      it { is_expected.to be_valid }
    end

    context 'when nil one was already taken' do
      subject(:second_user) { build(:user, documentation: nil) }

      before { create(:user, documentation: nil) }

      it { is_expected.to be_valid }
    end

    context 'when valid one was already taken' do
      subject(:second_user) do
        build(:user, documentation: first_user.documentation)
      end

      let!(:first_user) { create(:user) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#date_of_birth' do
    context 'when is nil' do
      subject(:user) { build(:user, date_of_birth: nil) }

      it { is_expected.to be_valid }
    end

    context 'when format is invalid' do
      subject(:user) { build(:user, date_of_birth: 'not_a_valid_date') }

      it 'must treat as nil' do
        expect(user).to be_valid
      end
    end

    context 'when is in the future' do
      subject(:user) { build(:user, date_of_birth: 1.day.from_now) }

      it { is_expected.to be_invalid }
    end

    context 'when is today' do
      subject(:user) { build(:user, date_of_birth: Time.current) }

      it { is_expected.to be_valid }
    end
  end

  describe '#confirmed_at' do
    context 'when is nil' do
      subject(:user) { build(:user, confirmed_at: nil) }

      it { is_expected.to be_valid }
    end

    context 'when is setted on creation' do
      subject(:user) { build(:user, confirmed_at: Time.current) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#confirm!' do
    context 'when not yet confirmed' do
      subject(:user) { create(:user) }

      it do
        expect { user.confirm! }.to change(user, :confirmed_at)
          .from(nil).to(be_present)
      end
    end

    context 'when already confirmed' do
      subject(:user) { create(:user, :confirmed) }

      it { expect { user.confirm! }.not_to change(user, :confirmed_at) }
    end
  end

  describe '#confirmed?' do
    context 'when not yet confirmed' do
      subject(:user) { create(:user) }

      it { is_expected.not_to be_confirmed }
    end

    context 'when already confirmed' do
      subject(:user) { create(:user, :confirmed) }

      it { is_expected.to be_confirmed }
    end
  end
end
