# frozen_string_literal: true

# Liste des appels à CreneauxBuilderSerices.perform_with
# `grep -r "CreneauxBuilderService" app`
#
# - app/services/concerns/users/creneaux_search_concern.rb:11
# CreneauxBuilderService.perform_with(motif.name, @lieu, date_range, **options)
#
#    @options ||= {
#      agent_ids: agent_ids,
#      agent_name: follow_up_rdv_and_online_user?,
#      motif_location_type: motif.location_type,
#      service: motif.service
#    }.select { |_key, value| value } # rejects false and nil but not [] or 0
#
#
module SlotBuilder
  # À faire avant, au moment de jouer avec le motifs
  # @for_agents ? motifs : motifs.reservable_online
  # Ce filtre est lié à la recherche de plage d'ouverture à partir d'un nom de motif... Est-ce vraiment nécessaire dans notre cas ?
  #
  # @for_agents sert aussi pour « limiter » l'afficahge des créneaux. Je pense que c'est à faire sur la vue.
  # uniq_by = @for_agents ? ->(c) { [c.starts_at, c.agent_id] } : ->(c) { c.starts_at }
  #  creneaux.uniq(&uniq_by).sort_by(&:starts_at)

  def self.available_slots(motif, lieu, date_range, off_days, options = {})
    # options : { agents: [] }
    plage_ouvertures = plage_ouvertures_for(motif, lieu, date_range, options)
    free_times = free_times_from(plage_ouvertures, date_range, off_days) # dépendance sur RDV et Absence
    slots_for(free_times, motif)
  end

  def self.plage_ouvertures_for(motif, lieu, date_range, options = {})
    lieu.plage_ouvertures.for_motif_object(motif).not_expired.in_range(date_range)
      .where(({ agent_id: options[:agent_ids] } unless options[:agent_ids].nil?))
  end

  def self.free_times_from(plage_ouvertures, date_range, off_days)
    free_times = {}
    plage_ouvertures.each do |plage_ouverture|
      free_times[plage_ouverture] = calculate_free_times(plage_ouverture, date_range, off_days)
    end
    free_times.select { |_, v| v&.any? }
  end

  def self.calculate_free_times(plage_ouverture, date_range, _off_days)
    ranges = ranges_for(plage_ouverture, date_range)

    return [] if ranges.empty?

    rdvs = []
    ranges.each do |range|
      rdvs += plage_ouverture.agent.rdvs.not_cancelled.where(starts_at: range).or(plage_ouverture.agent.rdvs.not_cancelled.where(ends_at: range))
    end
    # TODO: ajouter la recherche des occurrences qui correspondent à la période
    absences = []
    ranges.each do |range|
      absences += plage_ouverture.agent.absences.where(first_day: range).or(plage_ouverture.agent.absences.where(end_day: range))
    end

    # c'est là que l'on execute le SQL
    busy_times = rdvs + absences

    ranges = ranges.map { |range| split_range_recursively(range, busy_times) }.flatten
    ranges.select { |r| ((r.end.to_i - r.begin.to_i) / 60).positive? } || []
  end

  def self.ranges_for(plage_ouverture, date_range)
    date_range = Time.zone.now..date_range.end.end_of_day if date_range.begin < Time.zone.now
    occurrences = plage_ouverture.occurrences_for(date_range)

    occurrences.map do |occurrence|
      next if occurrence.ends_at < Time.zone.now

      (occurrence.starts_at..occurrence.ends_at)
    end
  end

  def self.split_range_recursively(range, busy_times)
    return [range] if busy_times.empty?

    busy_time = busy_times.first

    if rdv_include_in_range?(busy_time, range)
      [range.begin..busy_time.starts_at] + split_range_recursively(busy_time.ends_at..range.end, busy_times - [busy_time])
    elsif rdv_overlap_begin_of_range?(busy_time, range)
      split_range_recursively(busy_time.ends_at..range.end, busy_times - [busy_time])
    elsif rdv_overlap_end_of_range?(busy_time, range)
      split_range_recursively(range.begin..busy_time.starts_at, busy_times - [busy_time])
    else
      [range]
    end
  end

  def self.rdv_include_in_range?(rdv, range)
    range.begin < rdv.starts_at && rdv.ends_at <= range.end
  end

  def self.rdv_overlap_begin_of_range?(rdv, range)
    rdv.starts_at <= range.begin
  end

  def self.rdv_overlap_end_of_range?(rdv, range)
    range.end <= rdv.ends_at
  end

  def self.slots_for(plage_ouverture_free_times, motif)
    slots = []
    plage_ouverture_free_times.each do |plage_ouverture, free_times|
      free_times.each do |free_time|
        slots += calculate_slots(free_time, motif) do |starts_at|
          Creneau.new(
            starts_at: starts_at,
            motif: motif,
            lieu_id: plage_ouverture.lieu_id,
            agent_id: plage_ouverture.agent_id,
            agent_name: plage_ouverture.agent.full_name
          )
        end
      end
    end
    slots
  end

  def self.calculate_slots(free_time, motif, &build_creneau)
    slots = []
    possible_slot_time = free_time.begin..(free_time.begin + motif.default_duration_in_min.minutes)
    while possible_slot_time.end <= free_time.end
      slots << build_creneau.call(possible_slot_time.begin)
      possible_slot_time = possible_slot_time.end..(possible_slot_time.end + motif.default_duration_in_min.minutes)
    end
    slots
  end
end
