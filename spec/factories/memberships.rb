FactoryGirl.define do
  factory :membership do
    id { SecureRandom.uuid }
    user
    project
  end

end
