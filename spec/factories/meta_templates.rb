FactoryGirl.define do
  factory :meta_template do
    association :templatable, factory: :data_file
    template

    trait :skip_validation do
      to_create {|instance| instance.save(validate: false) }
    end
  end
end
