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
      creneaux = CreneauxBuilderService.perform_with(@motif_name, @lieu, date..(date + 7.days), **@creneaux_builder_options)
      available_creneau = creneaux.first if creneaux.any?
    end
    available_creneau
  end
end
