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
  end

  describe '#token' do
    context 'when is nil' do
      subject(:access_token) { build(:access_token, token: nil) }

      it :aggregate_failures do
        expect(access_token).to be_valid
        expect(access_token.token).to be_present
      end
    end

    context 'when is blank' do
      subject(:access_token) { build(:access_token, token: '') }

      it :aggregate_failures do
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
  end

  describe '#revoked_at' do
    context 'when is nil' do
      subject(:access_token) { build(:access_token, revoked_at: nil) }

      it { is_expected.to be_valid }
    end

    context 'when is setted on creation' do
      subject(:access_token) { build(:access_token, revoked_at: Time.current) }

      it { is_expected.to be_invalid }
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

      context 'when it has not yet expired' do
        before { create_list(:access_token, 2) }

        it 'must order tokens by created_at desc', :aggregate_failures do
          expect(usable_access_tokens.count).to eq(2)
          expect(usable_access_tokens.first.created_at)
            .to be > usable_access_tokens.second.created_at
        end
      end

      # TODO: create a context with ttl setted as env
      context 'when it has expired - default TTL' do
        let(:access_token_ttl) { described_class::TTL }

        before do
          travel_to(access_token_ttl.ago) { create(:access_token) }
          create(:access_token)
        end

        it :aggregate_failures do
          expect(usable_access_tokens.count).to eq(1)
          expect(described_class.count).to eq(2)
        end
      end
    end
  end
end
