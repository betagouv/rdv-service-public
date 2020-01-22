FactoryBot.define do
  factory :file_attente do
    rdv { Rdv.first || create(:organisation) }
    user { User.first || create(:organisation) }
  end
end
