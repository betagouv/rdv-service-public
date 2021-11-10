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
      # NOTE: LOOP 2 loop here for ~ 27 weeks
      # We break out of the loop once we find a creneau.
      creneaux = CreneauxBuilderService
        .perform_with(
          @motif_name,
          @lieu,
          date..(date + 7.days),
          **@creneaux_builder_options
        )
      # NOTE: We build the whole list of creneayx of the week just to return the first one.
      available_creneau = creneaux.first if creneaux.any?
    end
    available_creneau
  end
end
