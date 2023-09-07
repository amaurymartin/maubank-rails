# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  born_on         :date
#  confirmed_at    :datetime
#  documentation   :text
#  email           :text             not null
#  full_name       :text
#  key             :uuid             not null
#  nickname        :text             not null
#  password_digest :text             not null
#  username        :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_documentation  (documentation) UNIQUE
#  index_users_on_email          (email) UNIQUE
#  index_users_on_key            (key) UNIQUE
#  index_users_on_username       (username) UNIQUE
#
require 'rails_helper'

RSpec.describe User do
  describe '#validate' do
    subject(:user) { build(:user) }

    it { is_expected.to be_valid }
  end

  describe '#key' do
    context 'when is nil' do
      subject(:user) { build(:user, key: nil) }

      it 'must auto generate', :aggregate_failures do
        expect(user).to be_valid
        expect(user.key).to be_present
      end
    end

    context 'when is blank' do
      subject(:user) { build(:user, key: '') }

      it 'must auto generate', :aggregate_failures do
        expect(user).to be_valid
        expect(user.key).to be_present
      end
    end

    context 'when is invalid' do
      subject(:user) { build(:user, key: invalid_key) }

      let(:invalid_key) { 'invalid_key' }

      it 'must auto generate', :aggregate_failures do
        expect(user).to be_valid
        expect(user.key).not_to eq(invalid_key)
      end
    end

    context 'when already taken' do
      subject(:second_user) { build(:user, key: first_user.key) }

      let(:first_user) { create(:user) }

      it :aggregate_failures do
        expect(second_user).not_to be_valid
        expect(second_user.errors)
          .to be_added(:key, :taken, { value: first_user.key })
      end
    end

    context 'when is read-only' do
      subject(:user) { create(:user) }

      it do
        expect { user.update(key: SecureRandom.uuid) && user.reload }
          .not_to change(user, :key)
      end
    end
  end

  describe '#full_name' do
    context 'when is nil' do
      subject(:user) { build(:user, full_name: nil) }

      it { is_expected.to be_valid }
    end

    context 'when is blank' do
      subject(:user) { build(:user, full_name: '') }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(:full_name, :blank)
      end
    end
  end

  describe '#nickname' do
    context 'when is nil' do
      subject(:user) { build(:user, nickname: nil) }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(:nickname, :blank)
      end
    end

    context 'when is blank' do
      subject(:user) { build(:user, nickname: '') }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(:nickname, :blank)
      end
    end
  end

  describe '#username' do
    context 'when is nil' do
      subject(:user) { build(:user, username: nil) }

      it { is_expected.to be_valid }
    end

    context 'when is blank' do
      subject(:user) { build(:user, username: '') }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(:username, :blank)
      end
    end

    context 'when nil was already taken' do
      subject(:second_user) { build(:user, username: nil) }

      before { create(:user, username: nil) }

      it { is_expected.to be_valid }
    end

    context 'when valid one was already taken' do
      subject(:second_user) { build(:user, username: first_user.username) }

      let(:first_user) { create(:user) }

      it :aggregate_failures do
        expect(second_user).not_to be_valid
        expect(second_user.errors)
          .to be_added(:username, :taken, { value: first_user.username })
      end
    end

    context 'when already taken case insensitive' do
      subject(:second_user) do
        build(:user, username: first_user.username.upcase)
      end

      let(:first_user) { create(:user) }

      it 'upper and lower case must be seen as style', :aggregate_failures do
        expect(second_user).not_to be_valid
        expect(second_user.errors)
          .to be_added(:username, :taken, { value: first_user.username.upcase })
      end
    end
  end

  describe '#email' do
    context 'when is nil' do
      subject(:user) { build(:user, email: nil) }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(:email, :blank)
      end
    end

    context 'when is blank' do
      subject(:user) { build(:user, email: '') }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(:email, :blank)
      end
    end

    context 'when is invalid' do
      subject(:user) { build(:user, email: invalid_email) }

      let(:invalid_email) { 'not_a_valid_email' }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(
          :email, :invalid_email, { value: invalid_email }
        )
      end
    end

    context 'when already taken' do
      subject(:second_user) { build(:user, email: first_user.email) }

      let(:first_user) { create(:user) }

      it :aggregate_failures do
        expect(second_user).not_to be_valid
        expect(second_user.errors)
          .to be_added(:email, :taken, { value: first_user.email })
      end
    end

    context 'when already taken case insensitive' do
      subject(:second_user) do
        build(:user, email: first_user.email.upcase)
      end

      let(:first_user) { create(:user) }

      it 'emails must be case insensitive', :aggregate_failures do
        expect(second_user).not_to be_valid
        expect(second_user.errors)
          .to be_added(:email, :taken, { value: first_user.email.upcase })
      end
    end

    context 'when is read-only' do
      subject(:user) { create(:user) }

      it do
        expect { user.update(email: Faker::Internet.email) && user.reload }
          .not_to change(user, :email)
      end
    end
  end

  describe '#password' do
    context 'when is nil' do
      subject(:user) { build(:user, password: nil) }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(:password, :blank)
      end
    end

    context 'when is blank' do
      subject(:user) { build(:user, password: '') }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(:password, :blank)
      end
    end

    context 'when has less than 8 characters' do
      subject(:user) { build(:user, password: 'short') }

      it 'must has at least 8 characters', :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(:password, :too_short, { count: 8 })
      end
    end
  end

  describe '#password_confirmation' do
    context 'when is nil' do
      subject(:user) { build(:user, password_confirmation: nil) }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(:password_confirmation, :blank)
      end
    end

    context 'when is blank' do
      subject(:user) { build(:user, password_confirmation: '') }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(:password_confirmation, :blank)
      end
    end

    context 'when is not equal to password' do
      subject(:user) { build(:user, password_confirmation: 'different') }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(
          :password_confirmation, :confirmation, { attribute: 'Password' }
        )
      end
    end

    context 'when password is not being updated' do
      subject(:user) { create(:user) }

      before { user.full_name = Faker::Name.name }

      it { expect { user.save }.to change(user, :attributes) }
    end

    context 'when password is being updated' do
      subject(:user) { create(:user) }

      before { user.password = Faker::Internet.password(min_length: 8) }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(
          :password_confirmation, :confirmation, { attribute: 'Password' }
        )
      end
    end
  end

  describe '#documentation' do
    context 'when is nil' do
      subject(:user) { build(:user, documentation: nil) }

      it { is_expected.to be_valid }
    end

    context 'when is blank' do
      subject(:user) { build(:user, documentation: '') }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(:documentation, :invalid)
      end
    end

    context 'when is not a brazilian CPF' do
      subject(:user) { build(:user, documentation: 'invalid') }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(:documentation, :invalid)
      end
    end

    context 'when is not a brazilian CPF but allows other values' do
      subject(:user) { build(:user, documentation: 'not_brazilian_cpf') }

      before { stub_const('User::ONLY_BRAZILIAN_CPF', false) }

      it { is_expected.to be_valid }
    end

    context 'when nil was already taken' do
      subject(:second_user) { build(:user, documentation: nil) }

      before { create(:user, documentation: nil) }

      it { is_expected.to be_valid }
    end

    context 'when valid one was already taken' do
      subject(:second_user) do
        build(:user, documentation: first_user.documentation)
      end

      let(:first_user) { create(:user) }

      it :aggregate_failures do
        expect(second_user).not_to be_valid
        expect(second_user.errors).to be_added(
          :documentation, :taken, { value: first_user.documentation }
        )
      end
    end

    context 'when is formatted' do
      subject(:user) { build(:user, :formatted_documentation) }

      let(:stripped) { user.documentation.gsub(/[.-]/, '') }

      it do
        expect { user.validate }.to change(user, :documentation)
          .from(user.documentation).to(stripped)
      end
    end
  end

  describe '#born_on' do
    context 'when is nil' do
      subject(:user) { build(:user, born_on: nil) }

      it { is_expected.to be_valid }
    end

    context 'when format is invalid' do
      subject(:user) { build(:user, born_on: 'not_a_valid_date') }

      it 'must treat as nil' do
        expect(user).to be_valid
      end
    end

    context 'when is in the future' do
      subject(:user) { build(:user, born_on: date_in_future) }

      let(:date_in_future) { Date.current + 1.day }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(
          :born_on, :less_than_or_equal_to,
          { value: date_in_future, count: Date.current }
        )
      end
    end

    context 'when is today' do
      subject(:user) { build(:user, born_on: Date.current) }

      it { is_expected.to be_valid }
    end
  end

  describe '#confirmed_at' do
    context 'when is nil' do
      subject(:user) { build(:user, confirmed_at: nil) }

      it { is_expected.to be_valid }
    end

    context 'when is set at creation' do
      subject(:user) { build(:user, confirmed_at: Time.current) }

      it :aggregate_failures do
        expect(user).not_to be_valid
        expect(user.errors).to be_added(:confirmed_at, :present)
      end
    end
  end

  describe '#created_at' do
    context 'when is read-only' do
      subject(:user) { create(:user) }

      it do
        expect { user.update(created_at: Time.current) && user.reload }
          .not_to change(user, :created_at)
      end
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

  describe '#to_param' do
    let(:user) { create(:user) }

    it { expect(user.to_param).to eq(user.key) }
  end

  describe 'dependent delete_all' do
    context 'with access token' do
      let(:user) { create(:user, :with_access_token) }
      let(:user_access_tokens) { user.access_tokens }

      it do
        expect { user.destroy }.to change(AccessToken, :count)
          .by(-user_access_tokens.size)
      end
    end

    context 'with category' do
      let(:user) { create(:user, :with_category) }
      let(:user_categories) { user.categories }

      it do
        expect { user.destroy }.to change(Category, :count)
          .by(-user_categories.size)
      end
    end

    context 'with goal' do
      let(:user) { create(:user, :with_goal) }
      let(:user_goals) { user.goals }

      it do
        expect { user.destroy }.to change(Goal, :count)
          .by(-user_goals.size)
      end
    end

    context 'with wallet' do
      let(:user) { create(:user, :with_wallet) }
      let(:user_wallets) { user.wallets }

      it do
        expect { user.destroy }.to change(Wallet, :count)
          .by(-user_wallets.size)
      end
    end
  end
end
