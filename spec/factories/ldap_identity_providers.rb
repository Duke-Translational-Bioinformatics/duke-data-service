FactoryGirl.define do
  factory :ldap_identity_provider do
    host { Faker::Internet.url }
    port { Faker::Address.zip_code }
    ldap_base { SecureRandom.hex }
  end
end
