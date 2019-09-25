FactoryBot.define do
  factory :absence do
    organisation { Organisation.first || create(:organisation) }
    pro { Pro.first || create(:pro) }
    starts_at { Time.zone.local(2019, 7, 4, 15, 0) }
    ends_at { Time.zone.local(2019, 7, 4, 15, 30) }
  end
end
