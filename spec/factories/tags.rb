FactoryGirl.define do
  factory :tag do
    label { Faker::Hacker.say_something_smart }
    association :taggable, factory: :data_file

  end
end
