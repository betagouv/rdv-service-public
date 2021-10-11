# frozen_string_literal: true

class RdvsOverlapping
  delegate :starts_at, :ends_at, :duration_in_min, :agents, to: :rdv
  attr_reader :rdv

  def initialize(rdv)
    @rdv = rdv
  end

  def rdvs_overlapping_rdv
    Rdv.where.not(id: @rdv.id)
      .not_cancelled
      .future
      .with_agent_among(agents)
      .where("tsrange(starts_at, ends_at, '[)') && tsrange(?, ?)", starts_at, ends_at)
      .order(:ends_at)
  end

  def rdvs_overlapping_rdv?
    rdvs_overlapping_rdv.any?
  end
end
