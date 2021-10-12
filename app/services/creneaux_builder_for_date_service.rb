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

  # rubocop: disable Lint/ToEnumArguments
  def perform
    @next_starts_at = @plage_ouverture.start_time.on(@date)
    to_enum(:next_creneaux).to_a.compact # enumerator entry
  end
  # rubocop: enable Lint/ToEnumArguments

  private

  def next_creneaux
    creneau = generate_creneau
    return if no_more_creneaux_for_the_day?(creneau)

    events = rdvs + absences_occurrences
    last_overlapping_ends_at = creneau.last_overlapping_event_ends_at(events)
    if last_overlapping_ends_at.present?
      return if last_overlapping_ends_at.to_date > @date

      @next_starts_at = last_overlapping_ends_at
    elsif !@for_agents && !creneau.respects_booking_delays?
      @next_starts_at += @motif.default_duration_in_min.minutes
    else
      yield creneau # yeah we found one
      @next_starts_at = creneau.ends_at # set the value for the nex call to generate_creneau
    end

    next_creneaux { yield _1 } # (recurse and yield the enumerator) … which happens in here.
    # The passed block is yielded to by the called function. Inside this passed block, we yield _out_ to the callee, which, in the root next_creneaux call, adds to the collection.
    # The idea is that the method called by to_enum is supposed to call yield with an argument, a number of times. The arguments passed to yield are the collection.
    # I think this recursion goes quite deep.
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
    @absences_occurrences ||= @plage_ouverture.agent.absences.flat_map { _1.occurrences_for(inclusive_datetime_range) }
  end

  def inclusive_datetime_range
    @inclusive_datetime_range ||= (@inclusive_date_range.begin)..(@inclusive_date_range.end.end_of_day)
  end
end
