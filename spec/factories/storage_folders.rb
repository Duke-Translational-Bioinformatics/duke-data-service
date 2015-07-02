FactoryGirl.define do
  factory :storage_folder do
    project_id { Faker::Number.number(8) }
    name { Faker::Team.name }
    description { Faker::Hacker.say_something_smart }
    storage_service_uuid { SecureRandom.uuid }
  end

end
