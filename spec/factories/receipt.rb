FactoryBot.define do
  factory :receipt do
    rdv
    user
    event { :rdv_created }
    channel { :sms }
    result { :processed }
    sms_count { 2 }
    sms_phone_number { Faker::PhoneNumber.cell_phone }
    content { "Atelier collectif, mardi 20/02 à 16h00. Mairie de Romainville (7 Rue de Paris, Romainville, 93230). Infos et annulation: https://demo.rdv-solidarites.fr/r/asdfasd/ / 0100001111" }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }

    trait :mail do
      content { "Vous avez RDV" }
      channel { :mail }
      sms_count { nil }
      sms_phone_number { nil }
      email_address { user.email || Faker::Internet.email }
    end
  end
end
