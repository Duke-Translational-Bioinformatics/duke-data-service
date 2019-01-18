FactoryBot.define do
  factory :ldap_identity_provider do
    host { Faker::Internet.domain_name }
    port { Faker::Number.number(5) }
    ldap_base { "dc=#{Faker::Internet.domain_word},dc=#{Faker::Internet.domain_suffix}" }
  end
end
