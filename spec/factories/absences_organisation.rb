# frozen_string_literal: true

FactoryBot.define do
  factory :absences_organisation do
    association(:absence)
    association(:organisation)
  end
end
