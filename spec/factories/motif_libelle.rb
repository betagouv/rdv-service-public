# frozen_string_literal: true

FactoryBot.define do
  sequence(:libelle_name) { |n| "Libellé n°#{n}" }

  factory :motif_libelle do
    service { create(:service) }

    name { generate(:libelle_name) }
  end
end
