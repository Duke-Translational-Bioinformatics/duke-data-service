FactoryGirl.define do
  factory :membership do
    user_id { Faker::Number.number(8) }
    project_id { Faker::Number.number(8) }
  end

end
