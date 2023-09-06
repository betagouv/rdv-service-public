# frozen_string_literal: true

FactoryBot.define do
  factory :receipt do
    rdv
    user
    event { :rdv_created }
    channel { :sms }
    result { :processed }
    sms_phone_number { user.phone_number }
    email_address { user.email }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
  end
end
