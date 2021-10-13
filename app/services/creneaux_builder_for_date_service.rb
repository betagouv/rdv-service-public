# frozen_string_literal: true

class CreneauxBuilderForDateService < BaseService
  def initialize(plage_ouverture, motif, date, lieu, **options)
    @plage_ouverture = plage_ouverture
    @motif = motif
    @date = date
    @lieu = lieu
    @inclusive_date_range = options[:inclusive_date_range]
    @for_agents = options.fetch(:for_agents, false)
    @agent_name = options.fetch(:agent_name, false)
  end

  def perform
    creneaux = []

    # Loop over the tentative creneaux, by filling from the start_time of the PlageOuverture.
    next_starts_at = @plage_ouverture.start_time.on(@date)
    loop do
      tentative_creneau = new_creneau(next_starts_at)
      # Stop when we reach the end of the PlageOuverture (or the end of the day)
      break if no_more_creneaux_for_the_day?(tentative_creneau)

      # If this tentative overlaps with existing Rdvs or Absence, skip ahead to the end of the last overlap
      possible_overlaps = rdvs + absences_occurrences
      last_overlapping_ends_at = tentative_creneau.last_overlapping_event_ends_at(possible_overlaps)
      if last_overlapping_ends_at.present?
        next_starts_at = last_overlapping_ends_at

      # If the motif has a booking delay, skip ahead by the default duration of the motif
      # NOTE: I’m not sure this make sense. min_booking_delay and default_duration_in_min are two distinct things.
      # The booking delay isn’t a minimum delay between Rdvs, but the advance delay since the current date.
      elsif !@for_agents && !tentative_creneau.respects_booking_delays?
        next_starts_at += @motif.default_duration_in_min.minutes

      #  Otherwise, we found a vald crenau! Save it and continue.
      else
        creneaux << tentative_creneau
        next_starts_at = tentative_creneau.ends_at
      end
    end

    creneaux
  end

  private

  def new_creneau(next_starts_at)
    Creneau.new(
      starts_at: next_starts_at,
      lieu_id: @lieu.id,
      motif: @motif,
      agent_id: @plage_ouverture.agent_id,
      agent_name: (@plage_ouverture.agent.short_name if @for_agents || @agent_name)
    )
  end

  def no_more_creneaux_for_the_day?(creneau)
    creneau.ends_at.to_time_of_day > @plage_ouverture.end_time ||
      creneau.ends_at.to_date > creneau.starts_at.to_date ||
      creneau.overlaps_jour_ferie? ||
      creneau.ends_at.to_date > @date
  end

  def rdvs
    @rdvs ||= @plage_ouverture.agent.rdvs.where(starts_at: inclusive_datetime_range).not_cancelled.to_a
  end

  def absences_occurrences
    @absences_occurrences ||= @plage_ouverture.agent.absences.flat_map { _1.occurrences_for(inclusive_datetime_range) }
  end

  def inclusive_datetime_range
    @inclusive_datetime_range ||= (@inclusive_date_range.begin)..(@inclusive_date_range.end.end_of_day)
  end
end
