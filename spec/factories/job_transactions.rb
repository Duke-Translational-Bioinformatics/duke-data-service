FactoryGirl.define do
  factory :job_transaction do
    association :transactionable, factory: :project
    key { Faker::App.name }
    state { Faker::Hacker.say_something_smart }
  end
end
