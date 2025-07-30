FactoryBot.define do
  factory :annotation do
    user
    territory
    content { "Cet usager est sympa" }
  end
end
