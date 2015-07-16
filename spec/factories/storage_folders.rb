FactoryGirl.define do
  factory :storage_folder do
    project_id { SecureRandom.uuid }
    name { Faker::Team.name }
    description { Faker::Hacker.say_something_smart }
    storage_service_uuid { SecureRandom.uuid }
  end

end
