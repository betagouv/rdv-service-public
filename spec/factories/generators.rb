FactoryBot.define do
  sequence(:valid_password) do
    "Aa1_#{Faker::Internet.password(min_length: 12, mix_case: true, special_characters: true)}"
  end
end
