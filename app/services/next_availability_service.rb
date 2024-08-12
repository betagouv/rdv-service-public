class NextAvailabilityService
  def self.find(motif, lieu, agents, from:, to: nil)
    from = from.to_datetime # rubocop:disable Style/DateTime
    to = to&.to_datetime || (from + 6.months) # rubocop:disable Style/DateTime

    from.step(to, 7).find do |date|
      # NOTE: LOOP 2 loop here for ~ 27 weeks
      # We break out of the loop once we find a creneau.

      max_creneau_date = [to, date + 7.days].min

      creneaux = SlotBuilder.available_slots(motif, lieu, date..max_creneau_date, agents)
      # NOTE: We build the whole list of creneaux of the week just to return the first one.
      return creneaux.min if creneaux.any?
    end

    nil # return nil if nothing found in loop
  end
end
