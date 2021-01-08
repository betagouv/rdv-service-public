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

  # rubocop: disable Lint/ToEnumArguments
  def perform
    @next_starts_at = @plage_ouverture.start_time.on(@date)
    to_enum(:next_creneaux).to_a.compact
  end
  # rubocop: enable Lint/ToEnumArguments

  private

  def next_creneaux
    creneau = generate_creneau
    return if no_more_creneaux_for_the_day?(creneau)

    overlapping_rdvs_or_absences = creneau.overlapping_rdvs_or_absences(rdvs + absences_occurrences)
    if overlapping_rdvs_or_absences.any?
      return if overlapping_rdvs_or_absences.first.ends_at.to_date > @date

      @next_starts_at = overlapping_rdvs_or_absences.first.ends_at
    elsif !@for_agents && !creneau.respects_booking_delays?
      @next_starts_at += @motif.default_duration_in_min.minutes
    else
      yield creneau
      @next_starts_at = creneau.ends_at
    end

    next_creneaux { yield _1 }
  end

  def generate_creneau
    Creneau.new(
      starts_at: @next_starts_at,
      lieu_id: @lieu.id,
      motif: @motif,
      agent_id: @plage_ouverture.agent_id,
      agent_name: (@plage_ouverture.agent.short_name if @for_agents || @agent_name)
    )
  end

  def no_more_creneaux_for_the_day?(creneau)
    creneau.ends_at.to_time_of_day > @plage_ouverture.end_time ||
      creneau.ends_at.to_date > creneau.starts_at.to_date ||
      creneau.overlaps_jour_ferie?
  end

  def rdvs
    @rdvs ||= @plage_ouverture.agent.rdvs.where(starts_at: inclusive_datetime_range).not_cancelled.to_a
  end

  def absences_occurrences
    @absences_occurrences ||= @plage_ouverture.agent.absences.flat_map { _1.occurences_for(inclusive_datetime_range) }
  end

  def inclusive_datetime_range
    @inclusive_datetime_range ||= (@inclusive_date_range.begin.to_time)..(@inclusive_date_range.end.end_of_day)
  end
end
