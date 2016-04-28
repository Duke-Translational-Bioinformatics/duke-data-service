FactoryGirl.define do
  factory :agent_activity_association do
    association :activity, factory: :activity
    factory :user_activity_association do
      association :agent, factory: :user
    end

    factory :software_agent_activity_association do
      association :agent, factory: :software_agent
    end
  end
end
