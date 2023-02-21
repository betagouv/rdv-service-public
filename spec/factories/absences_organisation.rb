# frozen_string_literal: true

FactoryBot.define do
  factory :absences_organisation do
    absence { association(:absence) }
    organisation { association(:organisation) }
  end
end
