# frozen_string_literal: true

class NextAvailabilityService
  def self.find(motif, lieu, from, **creneaux_builder_options)
    available_creneau = nil

    from.step(from + 6.months, 7).find do |date|
      # NOTE: LOOP 2 loop here for ~ 27 weeks
      # We break out of the loop once we find a creneau.
      #
      creneaux = SlotBuilder.available_slots(motif, date..(date + 7.days), lieu.organisation, OffDays.all_in_date_range(date..(date + 7.days)), **creneaux_builder_options)

      # NOTE: We build the whole list of creneaux of the week just to return the first one.
      available_creneau = creneaux.min_by(&:starts_at) if creneaux.any?
    end
    available_creneau
  end
end
