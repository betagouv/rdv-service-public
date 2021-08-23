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
      .where(id: (Rdv.select(:id).ends_at_in_range((starts_at + 1.second)..ends_at) +
                  Rdv.select(:id).starts_at_in_range(starts_at..(ends_at - 1.second)) +
                  Rdv.select(:id).where("starts_at < ?", starts_at).where("#{Rdv::ENDS_AT_SQL} > ?", ends_at)))
      .ordered_by_ends_at
  end

  def rdvs_overlapping_rdv?
    rdvs_overlapping_rdv.any?
  end
end
