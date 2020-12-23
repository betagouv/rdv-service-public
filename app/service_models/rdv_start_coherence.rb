class RdvStartCoherence
  delegate :starts_at, :duration_in_min, :agents, to: :rdv
  attr_reader :rdv

  THRESHOLD = 1.minute

  def initialize(rdv)
    @rdv = rdv
  end

  def rdvs_ending_shortly_before
    return [] if rdvs_ending_right_before?

    @rdvs_ending_shortly_before ||= all_rdvs_ending_before
      .select { _1.ends_at <= starts_at - THRESHOLD }
  end

  def rdvs_ending_shortly_before?
    rdvs_ending_shortly_before.any?
  end

  private

  def rdvs_ending_right_before
    @rdvs_ending_right_before ||= all_rdvs_ending_before
      .select { _1.ends_at > starts_at - THRESHOLD }
  end

  def rdvs_ending_right_before?
    rdvs_ending_right_before.any?
  end

  def all_rdvs_ending_before
    return Rdv.none if starts_at.blank? || duration_in_min.blank? || agents.blank?

    @all_rdvs_ending_before ||= Rdv
      .not_cancelled
      .future
      .with_agent_among(agents)
      .ends_at_in_range((starts_at - 46.minutes)..starts_at)
      .ordered_by_ends_at
      .to_a
  end
end
