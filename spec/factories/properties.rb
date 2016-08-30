FactoryGirl.define do
  factory :property do
    template
    key { "#{Faker::Name.first_name}_#{rand(10**3)}" }
    label { Faker::App.name }
    description { Faker::Hacker.say_something_smart }
    data_type { 'string' }

    trait :deprecated do
      is_deprecated true
    end
  end
end
