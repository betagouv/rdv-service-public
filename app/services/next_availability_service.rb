# frozen_string_literal: true

class NextAvailabilityService
  def self.find(motif, lieu, agents, from:, to: nil)
    available_creneau = nil
    from = from.beginning_of_day if from.is_a?(Date)
    to = to.beginning_of_day if to.is_a?(Date)
    to ||= from + 6.months

    from.step(to, 7).find do |date|
      # NOTE: LOOP 2 loop here for ~ 27 weeks
      # We break out of the loop once we find a creneau.

      max_creneau_date = [to, date + 7.days].min

      creneaux = SlotBuilder.available_slots(motif, lieu, date..max_creneau_date, OffDays.all_in_date_range(date..max_creneau_date), agents)
      # NOTE: We build the whole list of creneaux of the week just to return the first one.
      available_creneau = creneaux.min_by(&:starts_at) if creneaux.any?
    end
    available_creneau
  end
end
