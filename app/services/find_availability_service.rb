# frozen_string_literal: true

class FindAvailabilityService < BaseService
  def initialize(motif_name, lieu, from, **creneaux_builder_options)
    @motif_name = motif_name
    @lieu = lieu
    @from = from
    @creneaux_builder_options = creneaux_builder_options
  end

  def perform
    available_creneau = nil
    @from.step(@from + 6.months, 7).find do |date|
      creneaux = CreneauxBuilderService
        .perform_with(
          @motif_name,
          @lieu,
          date..(date + 7.days),
          plages_ouvertures: plages_ouvertures_cached,
          **@creneaux_builder_options
        )
      available_creneau = creneaux.first if creneaux.any?
    end
    available_creneau
  end

  private

  def plages_ouvertures_cached
    @plages_ouvertures_cached ||= CreneauxBuilderService
      .new(@motif_name, @lieu, nil, **@creneaux_builder_options)
      .plages_ouvertures
  end
end
