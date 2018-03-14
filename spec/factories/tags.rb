FactoryBot.define do
  factory :tag do
    sequence(:label) { |n| "#{Faker::Hacker.say_something_smart}#{n}" }
    association :taggable, factory: :data_file

    trait :skip_validation do
      to_create {|instance| instance.save(validate: false) }
    end
  end
end
