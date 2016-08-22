FactoryGirl.define do
  factory :tag do
    label { Faker::Hacker.say_something_smart }
    association :taggable, factory: :data_file

    trait :skip_validation do
      to_create {|instance| instance.save(validate: false) }
    end
  end
end
