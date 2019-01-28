FactoryBot.define do
  factory :auth_role do
    transient do
      without_permissions { false }
    end

    sequence(:id) { |n| "#{Faker::Internet.domain_word}_#{n}" }
    name { Faker::App.name }
    description { Faker::Hacker.say_something_smart }
    contexts  { (0..Faker::Number.digit.to_i).collect { Faker::Internet.slug } }

    permissions {
      if without_permissions
        AuthRole.available_permissions - (without_permissions.collect {|x| x.to_s})
      else
        (0..Faker::Number.digit.to_i).collect { Faker::Internet.domain_word }
      end
    }

    trait :system do
      contexts { %w(system) }
      permissions { AuthRole.available_permissions(:system) }
    end

    trait :project_admin do
      id { "project_admin" }
      name { "Project Admin" }
      description { "Can update project details, delete project, manage project level permissions and perform all file operations" }
      contexts { %w(project) }
      permissions { AuthRole.available_permissions(:project) }
    end

    trait :project_viewer do
      id { "project_viewer" }
      name { "Project Viewer" }
      description { "Can only view project and file meta-data" }
      contexts { %w(project) }
      permissions { %w(view_project) }
    end
    
    trait :random_id do
      id { "#{Faker::Internet.domain_word}_#{rand(10**3)}" }
    end

    trait :deprecated do
      is_deprecated { true }
    end
  end
end
