# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessToken, type: :model do
  describe '#validate' do
    subject(:access_token) { build(:access_token) }

    it { is_expected.to be_valid }
  end

  describe '#user' do
    context 'when is nil' do
      subject(:access_token) { build(:access_token, user: nil) }

      it { is_expected.to be_invalid }
    end

    context 'when is read-only' do
      subject(:access_token) { create(:access_token) }

      let(:other_user) { create(:user) }

      it do
        expect { access_token.update(user: other_user) && access_token.reload }
          .not_to change(access_token, :user)
      end
    end
  end

  describe '#token' do
    context 'when is nil' do
      subject(:access_token) { build(:access_token, token: nil) }

      it 'must auto generate', :aggregate_failures do
        expect(access_token).to be_valid
        expect(access_token.token).to be_present
      end
    end

    context 'when is blank' do
      subject(:access_token) { build(:access_token, token: '') }

      it 'must auto generate', :aggregate_failures do
        expect(access_token).to be_valid
        expect(access_token.token).to be_present
      end
    end

    context 'when is invalid' do
      let(:access_token) { build(:access_token, token: invalid_token) }

      let(:invalid_token) { 'invalid_token' }

      before do
        allow(access_token).to receive(:token).and_return(invalid_token)
      end

      it :aggregate_failures do
        expect(access_token).to be_invalid
        expect(access_token.errors)
          .to be_added(:token, :invalid, { value: invalid_token })
      end
    end

    context 'when already taken by same user' do
      let(:second_access_token) do
        build(:access_token, user: first_access_token.user)
      end
      let(:first_access_token) { create(:access_token) }

      before do
        allow(second_access_token)
          .to receive(:token)
          .and_return(first_access_token.token)
      end

      it :aggregate_failures do
        expect(second_access_token).to be_invalid
        expect(second_access_token.errors)
          .to be_added(:token, :taken, { value: first_access_token.token })
      end
    end

    context 'when already taken by other user' do
      let(:second_access_token) { build(:access_token) }
      let(:first_access_token) { create(:access_token) }

      before do
        allow(second_access_token)
          .to receive(:token)
          .and_return(first_access_token.token)
      end

      it :aggregate_failures do
        expect(second_access_token).to be_invalid
        expect(second_access_token.errors)
          .to be_added(:token, :taken, { value: first_access_token.token })
      end
    end

    context 'when is read-only' do
      subject(:access_token) { create(:access_token) }

      let(:encrypted_token) { Digest::SHA256.hexdigest(SecureRandom.base58) }

      it do
        expect do
          access_token.update(token: encrypted_token) && access_token.reload
        end.not_to change(access_token, :token)
      end
    end
  end

  describe '#revoked_at' do
    context 'when is nil' do
      subject(:access_token) { build(:access_token, revoked_at: nil) }

      it { is_expected.to be_valid }
    end

    context 'when is set at creation' do
      subject(:access_token) { build(:access_token, revoked_at: Time.current) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#created_at' do
    context 'when is read-only' do
      subject(:access_token) { create(:access_token) }

      it do
        expect do
          access_token.update(created_at: Time.current) && access_token.reload
        end.not_to change(access_token, :created_at)
      end
    end
  end

  describe '#revoke!' do
    context 'when not yet revoked' do
      subject(:access_token) { create(:access_token) }

      it do
        expect { access_token.revoke! }.to change(access_token, :revoked_at)
          .from(nil).to(be_present)
      end
    end

    context 'when already revoked' do
      subject(:access_token) { create(:access_token, :revoked) }

      it do
        expect { access_token.revoke! }.not_to change(access_token, :revoked_at)
      end
    end
  end

  describe '#revoked?' do
    context 'when not yet revoked' do
      subject(:access_token) { create(:access_token) }

      it { is_expected.not_to be_revoked }
    end

    context 'when already revoked' do
      subject(:access_token) { create(:access_token, :revoked) }

      it { is_expected.to be_revoked }
    end
  end

  describe '#generated_token' do
    subject(:generated_token) { access_token.send(:generated_token) }

    context 'when it has not yet been created' do
      let(:access_token) { build(:access_token) }

      it { is_expected.to be_present }
    end

    context 'when it was already created' do
      let(:access_token) { create(:access_token) }

      it { is_expected.to be_nil }
    end

    context 'when it was already destroyed' do
      let(:access_token) { create(:access_token) }

      before { access_token.destroy }

      it { is_expected.to be_nil }
    end
  end

  describe 'scopes' do
    describe '.usable' do
      subject(:usable_access_tokens) { described_class.usable }

      context 'when at least one is usable' do
        before { create_list(:access_token, 2) }

        it 'must order tokens by created_at desc', :aggregate_failures do
          expect(usable_access_tokens.count).to eq(2)
          expect(usable_access_tokens.first.created_at)
            .to be > usable_access_tokens.second.created_at
        end
      end

      context 'when at least one has expired - default TTL' do
        let(:default_ttl_in_minutes) { described_class.ttl_in_minutes }

        before do
          travel_to(default_ttl_in_minutes.ago) { create(:access_token) }
          create(:access_token)
        end

        it :aggregate_failures do
          expect(usable_access_tokens.count).to eq(1)
          expect(described_class.count).to eq(2)
        end
      end

      context 'when at least one has expired - custom TTL' do
        subject(:access_token) { create(:access_token) }

        let(:default_ttl_in_minutes) { described_class.ttl_in_minutes }
        let(:custom_ttl_in_minutes) { 60 }

        before do
          travel_to(default_ttl_in_minutes.ago) { create(:access_token) }
          stub_const('AccessToken::TTL', custom_ttl_in_minutes)
          create(:access_token)
        end

        it :aggregate_failures do
          expect(usable_access_tokens.count).to eq(2)
          expect(described_class.count).to eq(2)
        end
      end
    end
  end
end
