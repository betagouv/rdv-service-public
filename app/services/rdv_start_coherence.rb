# frozen_string_literal: true

class RdvStartCoherence
  delegate :starts_at, :duration_in_min, to: :rdv
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
    return Rdv.none if starts_at.blank? || duration_in_min.blank?

    agents = rdv.agents
    agents = agents.to_a if rdv.new_record?

    @all_rdvs_ending_before ||= Rdv
      .not_cancelled
      .future
      .joins(:agents).where(agents: agents)
      .where(ends_at: (starts_at - 46.minutes)..starts_at)
      .order(:ends_at)
      .to_a
  end
end
