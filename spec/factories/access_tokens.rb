# frozen_string_literal: true

# == Schema Information
#
# Table name: access_tokens
#
#  id         :bigint           not null, primary key
#  revoked_at :datetime
#  token      :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_access_tokens_on_token    (token) UNIQUE
#  index_access_tokens_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :access_token do
    user

    trait :revoked do
      after(:create, &:revoke!)
    end
  end
end
