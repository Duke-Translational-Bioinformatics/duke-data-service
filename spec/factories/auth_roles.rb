FactoryGirl.define do
  factory :auth_role do
    id { "#{Faker::Internet.domain_word}_#{rand(10**3)}" }
    name { Faker::App.name }
    description { Faker::Hacker.say_something_smart }
    permissions { (0..Faker::Number.digit.to_i).collect { Faker::Internet.domain_word } }
    contexts  { (0..Faker::Number.digit.to_i).collect { Faker::Internet.slug } }
    is_deprecated false

    trait :system do
      contexts %w(system)
      permissions %w(system_admin)
    end

    trait :project_admin do
      id "project_admin"
      name "Project Admin"
      description "Can update project details, delete project, manage project level permissions and perform all file operations"
      contexts %w(project)
      permissions %w(view_project update_project delete_project manage_project_permissions download_file create_file update_file delete_file)
    end

    trait :deprecated do
      is_deprecated true
    end
  end

end
