FactoryBot.define do
  factory :annotation do
    user
    territory
    content { "Cet usager a une situation particulière" }
  end
end
