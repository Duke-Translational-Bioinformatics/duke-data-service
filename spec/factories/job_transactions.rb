FactoryBot.define do
  factory :job_transaction do
    association :transactionable, factory: :project
    sequence(:key) { |n| "#{Faker::App.name}_#{n}" }
    request_id { SecureRandom.uuid }
    state { Faker::Hacker.say_something_smart }

    trait :transactionable_dummy do
      association :transactionable, factory: :api_key
    end
  end
end
