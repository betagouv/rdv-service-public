# frozen_string_literal: true

class RdvsOverlapping
  delegate :starts_at, :ends_at, :duration_in_min, to: :rdv
  attr_reader :rdv

  def initialize(rdv)
    @rdv = rdv
  end

  def rdvs_overlapping_rdv
    return Rdv.none if starts_at.nil? || ends_at.nil? || starts_at > ends_at

    agents = rdv.agents
    agents = agents.to_a if rdv.new_record?

    Rdv.where.not(id: @rdv.id)
      .not_cancelled
      .future
      .joins(:agents).where(agents: agents)
      .where("tsrange(starts_at, ends_at, '[)') && tsrange(?, ?)", starts_at, ends_at)
      .order(:ends_at)
  end

  def rdvs_overlapping_rdv?
    rdvs_overlapping_rdv.any?
  end
end
