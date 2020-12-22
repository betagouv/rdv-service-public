class CreneauxBuilderForDateService < BaseService
  def initialize(plage_ouverture, motif, date, lieu, **options)
    @plage_ouverture = plage_ouverture
    @motif = motif
    @date = date
    @lieu = lieu
    @inclusive_date_range = options[:inclusive_date_range]
    @for_agents = options.fetch(:for_agents, false)
    @agent_name = options.fetch(:agent_name, false)
    rewind
  end

  def perform
    rewind
    next_creneaux_enumerator.to_a.compact
  end

  def rewind
    @next_starts_at = @plage_ouverture.start_time.on(@date)
  end

  def next_creneaux_enumerator
    Enumerator.new do |enum|
      loop do
        res = build_and_validate_creneau
        break if res.reached_last?

        enum << res.creneau if res.creneau.present?
      end
    end
  end

  private

  def build_and_validate_creneau
    creneau = build_creneau
    return OpenStruct.new(reached_last?: true) if no_more_creneaux_for_the_day?(creneau)

    overlapping_rdvs_or_absences = creneau.overlapping_rdvs_or_absences(rdvs + absences_occurrences)
    if overlapping_rdvs_or_absences.any? && overlapping_rdvs_or_absences.first.ends_at.to_date > @date
      OpenStruct.new(reached_last?: true)
    elsif overlapping_rdvs_or_absences.any?
      @next_starts_at = overlapping_rdvs_or_absences.first.ends_at
      OpenStruct.new(invalid: true)
    elsif !@for_agents && !creneau.respects_booking_delays?
      @next_starts_at += @motif.default_duration_in_min.minutes
      OpenStruct.new(invalid: true)
    else
      @next_starts_at = creneau.ends_at
      OpenStruct.new(creneau: creneau)
    end
  end

  def build_creneau
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
