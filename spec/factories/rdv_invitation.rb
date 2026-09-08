FactoryBot.define do
  factory :rdv_invitation do
    user { create(:user) }
    motif { create(:motif) }
    inviting_agent { create(:agent) }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
  end
end
