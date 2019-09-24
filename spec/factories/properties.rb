FactoryBot.define do
  factory :property do
    template
    sequence(:key) { |n| "#{Faker::Internet.slug(words: nil, glue: '_')}_#{n}" }
    label { Faker::App.name }
    description { Faker::Hacker.say_something_smart }
    data_type { 'string' }

    trait :deprecated do
      is_deprecated { true }
    end
  end
end
