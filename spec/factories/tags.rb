FactoryGirl.define do
  factory :tag do
    label { Faker::Hacker.say_something_smart }
    factory :tagged_file do
      association :taggable, factory: :data_file
    end
  end
end
