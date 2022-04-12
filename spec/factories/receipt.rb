# frozen_string_literal: true

FactoryBot.define do
  factory :receipt do
    rdv
    user
    event { :rdv_created }
    channel { :sms }
    result { :processed }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
  end
end
