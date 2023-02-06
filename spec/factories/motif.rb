# frozen_string_literal: true

FactoryBot.define do
  sequence(:motif_name) { |n| "Motif #{n}" }

  factory :motif do
    organisation { association(:organisation) }
    service { association(:service) }
    motif_category { association(:motif_category) }

    name { generate(:motif_name) }
    default_duration_in_min { 45 }
    min_public_booking_delay { 30.minutes.seconds }
    max_public_booking_delay { 6.months.seconds }
    color { "##{SecureRandom.hex(3)}" }
    instruction_for_rdv { "Intruction pour le RDV" }
    restriction_for_rdv { "Consigne pour le RDV" }
    bookable_publicly { true }
    location_type { :public_office }
    visibility_type { Motif::VISIBLE_AND_NOTIFIED }

    trait :with_rdvs do
      after(:create) do |motif|
        create_list(:rdv, 5, motif: motif, organisation: motif.organisation)
      end
    end

    trait :at_home do
      location_type { :home }
    end

    trait :at_public_office do
      location_type { :public_office }
    end

    trait :by_phone do
      location_type { :phone }
    end

    trait :collectif do
      collectif { true }
    end

    trait :for_secretariat do
      for_secretariat { true }
    end

    trait :invisible do
      visibility_type { Motif::INVISIBLE }
    end

    trait :visible_and_notified do
      visibility_type { Motif::VISIBLE_AND_NOTIFIED }
    end

    trait :visible_and_not_notified do
      visibility_type { Motif::VISIBLE_AND_NOT_NOTIFIED }
    end

    trait :sectorisation_level_departement do
      sectorisation_level { Motif::SECTORISATION_LEVEL_DEPARTEMENT }
    end

    trait :sectorisation_level_organisation do
      sectorisation_level { Motif::SECTORISATION_LEVEL_ORGANISATION }
    end

    trait :sectorisation_level_agent do
      sectorisation_level { Motif::SECTORISATION_LEVEL_AGENT }
    end
  end
end
