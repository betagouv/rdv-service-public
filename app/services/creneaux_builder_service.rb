class CreneauxBuilderService < BaseService
  def initialize(motif_name, lieu, inclusive_date_range, **options)
    @motif_name = motif_name
    @lieu = lieu
    @inclusive_date_range = inclusive_date_range
    @options = options
    @for_agents = options.fetch(:for_agents, false)
    @agent_ids = options.fetch(:agent_ids, nil)
    @agent_name = options.fetch(:agent_name, false)
  end

  def perform
    creneaux = plages_ouvertures.flat_map { |po| creneaux_for_plage_ouverture(po) }
    creneaux = creneaux.select { |c| c.starts_at >= Time.zone.now }
    uniq_by = @for_agents ? ->(c) { [c.starts_at, c.agent_id] } : ->(c) { c.starts_at }
    creneaux.uniq(&uniq_by).sort_by(&:starts_at)
  end

  private

  def plages_ouvertures
    @plages_ouvertures ||= PlageOuverture.for_motif_and_lieu_from_date_range(@motif_name, @lieu, @inclusive_date_range, @agent_ids)
  end

  def motifs_for_plage_ouverture(plage_ouverture)
    motifs = plage_ouverture.motifs.where(name: @motif_name).active
    @for_agents ? motifs : motifs.reservable_online
  end

  def creneaux_for_plage_ouverture(plage_ouverture)
    motifs_for_plage_ouverture(plage_ouverture)
      .flat_map { creneaux_for_plage_ouverture_and_motif(plage_ouverture, _1) }
  end

  def creneaux_for_plage_ouverture_and_motif(plage_ouverture, motif)
    plage_ouverture.occurences_for(@inclusive_date_range).flat_map do |occurence|
      CreneauxBuilderForDate
        .perform_with(plage_ouverture, motif, occurence.starts_at.to_date, @lieu, inclusive_date_range: @inclusive_date_range, **@options)
    end
  end
end

class CreneauxBuilderForDate < BaseService
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
    @next_starts_at = @plage_ouverture.start_time.on(@date)
    to_enum(:next_creneaux).to_a.compact
  end

  private

  def next_creneaux
    creneau = generate_creneau
    return if creneau.ends_at.to_time_of_day > @plage_ouverture.end_time || creneau.overlaps_jour_ferie?

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
      agent_id: (@plage_ouverture.agent_id if @for_agents),
      agent_name: (@plage_ouverture.agent.short_name if @for_agents || @agent_name)
    )
  end

  def rdvs
    @rdvs ||= @plage_ouverture.agent.rdvs.where(starts_at: inclusive_datetime_range).active.to_a
  end

  def absences_occurrences
    @absences_occurrences ||= @plage_ouverture.agent.absences.flat_map { _1.occurences_for(inclusive_datetime_range) }
  end

  def inclusive_datetime_range
    @inclusive_datetime_range ||= (@inclusive_date_range.begin.to_time)..(@inclusive_date_range.end.end_of_day)
  end
end
