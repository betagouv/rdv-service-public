FactoryBot.define do
  factory :rdv_plan do
    user { create(:user) }
    planning_agent { create(:agent) }
    oauth_application { create(:oauth_application) }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
  end
end
