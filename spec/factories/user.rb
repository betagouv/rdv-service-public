FactoryBot.define do
  sequence(:user_email) { |n| "usager_#{n}@lapin.fr" }

  factory :user do
    email { generate(:user_email) }
    first_name { "Roger" }
    last_name { "Lusager" }
    phone_number { "0712121212" }
    birth_date { Date.new(1990, 10, 12) }
    address { "20 avenue de Ségur, Paris" }
    organisation { build(:organisation) }
  end
end
