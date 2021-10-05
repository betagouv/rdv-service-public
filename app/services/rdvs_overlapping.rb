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
      .where(id: Rdv.none
                     .or(Rdv.where(ends_at: (starts_at + 1.second)..ends_at))
                     .or(Rdv.where(starts_at: starts_at..(ends_at - 1.second)))
                     .or(Rdv.where(starts_at: (..starts_at)).where(ends_at: ends_at..)))
      .order(:ends_at)
  end

  def rdvs_overlapping_rdv?
    rdvs_overlapping_rdv.any?
  end
end
