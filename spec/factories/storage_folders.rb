FactoryGirl.define do
  factory :storage_folder do
    project
    name { "#{Faker::Team.name}_#{rand(10**3)}" }
    description { Faker::Hacker.say_something_smart }
    storage_service_uuid { SecureRandom.uuid }
  end

end
