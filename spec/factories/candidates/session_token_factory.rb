FactoryBot.define do
  factory :candidate_session_token, class: 'Candidates::SessionToken' do
    association :candidate, factory: :candidate

    trait :expired do
      expired_at { 5.minutes.ago }
    end

    trait :auto_expired do
      created_at { Time.zone.now - 1.minute - Candidates::SessionToken::AUTO_EXPIRE }
    end

    trait :confirmed do
      confirmed_at { 5.minutes.ago }
    end
  end
end
