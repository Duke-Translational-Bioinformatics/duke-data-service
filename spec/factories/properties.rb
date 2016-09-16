FactoryGirl.define do
  factory :property do
    template
    sequence(:key) { |n| "#{Faker::Name.first_name}_#{n}" }
    label { Faker::App.name }
    description { Faker::Hacker.say_something_smart }
    data_type { 'string' }

    trait :deprecated do
      is_deprecated true
    end
  end
end
