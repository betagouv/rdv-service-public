FactoryBot.define do
  factory :rdv_plan do
    user { create(:user) }
    planning_agent { create(:agent) }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
  end
end
