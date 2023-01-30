# frozen_string_literal: true

FactoryBot.define do
  factory :user_profile do
    user
    organisation
    notes { nil }
    logement { :locataire }
  end
end
