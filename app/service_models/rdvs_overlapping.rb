class RdvsOverlapping
  delegate :starts_at, :ends_at, :duration_in_min, :agents, to: :rdv
  attr_reader :rdv

  THRESHOLD = 1.minute

  def initialize(rdv)
    @rdv = rdv
  end

  def rdvs_overlapping_rdv
    Rdv.where.not(id: @rdv.id)
      .not_cancelled
      .future
      .with_agent_among(agents)
      .where(id: (Rdv.select(:id).ends_at_in_range(starts_at..ends_at) +
                  Rdv.select(:id).starts_at_in_range(starts_at..ends_at)))
      .ordered_by_ends_at
  end

  def rdvs_overlapping_rdv?; end
end
