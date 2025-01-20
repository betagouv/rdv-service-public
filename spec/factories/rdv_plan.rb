FactoryBot.define do
  factory :rdv_plan do
    user
    planning_agent { association(:agent) }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
  end
end
