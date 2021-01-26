module Admin::RdvFormConcern
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Cautions
    include ActiveModel::Cautions::Callbacks
    include ActiveModel::Cautions::SafetyDecision

    attr_accessor :rdv

    delegate(*::Rdv.attribute_names, to: :rdv)
    delegate :motif, :organisation, :agents, :users, to: :rdv
    delegate :overlapping_plages_ouvertures, :overlapping_plages_ouvertures?, to: :rdv
    delegate :rdvs_ending_shortly_before, :rdvs_ending_shortly_before?, to: :rdv_start_coherence
    delegate :rdvs_overlapping_rdv, :rdvs_overlapping_rdv?, to: :rdvs_overlapping

    validate :validate_rdv
    caution :warn_overlapping_plage_ouverture
    caution :warn_rdvs_ending_shortly_before
    caution :warn_rdvs_overlapping_rdv
  end

  def save
    valid? && rdv.save
  end

  private

  def validate_rdv
    return if rdv.valid?

    rdv.errors.each { errors.add(_1, _2) }
  end

  def warn_overlapping_plage_ouverture
    return true unless overlapping_plages_ouvertures?

    overlapping_plages_ouvertures
      .map { PlageOuverturePresenter.new(_1, agent_context) }
      .each { warnings.add(:base, _1.overlaps_rdv_error_message, active: true) }
  end

  def warn_rdvs_ending_shortly_before
    return true unless rdvs_ending_shortly_before?

    rdv_agent_pairs_ending_shortly_before_grouped_by_agent.values.map do
      RdvEndingShortlyBeforePresenter.new(
        rdv: _1.rdv,
        agent: _1.agent,
        rdv_context: rdv,
        agent_context: agent_context
      )
    end.each { warnings.add(:base, _1.warning_message, active: true) }
  end

  def warn_rdvs_overlapping_rdv
    return true unless rdvs_overlapping_rdv?

    rdv_agent_pairs_rdvs_overlapping_grouped_by_agent.values.map do
      RdvsOverlappingRdvPresenter.new(
        rdv: _1.rdv,
        agent: _1.agent,
        rdv_context: rdv,
        agent_context: agent_context
      )
    end.each { warnings.add(:base, _1.warning_message, active: true) }
  end

  def rdv_agent_pairs_ending_shortly_before_grouped_by_agent
    rdvs_ending_shortly_before
      .flat_map do |rdv_before|
        rdv_before.agents.select { rdv.agents.include?(_1) }.map { OpenStruct.new(agent: _1, rdv: rdv_before) }
      end
      .group_by(&:agent)
      .transform_values(&:last)
  end

  def rdv_agent_pairs_rdvs_overlapping_grouped_by_agent
    rdvs_overlapping_rdv
      .flat_map do |rdv_overlapping|
        rdv_overlapping.agents.select { rdv.agents.include?(_1) }.map { OpenStruct.new(agent: _1, rdv: rdv_overlapping) }
      end
      .group_by(&:agent)
      .transform_values(&:last)
  end

  def rdvs_overlapping
    @rdvs_overlapping ||= RdvsOverlapping.new(rdv)
  end

  def rdv_start_coherence
    @rdv_start_coherence ||= RdvStartCoherence.new(rdv)
  end
end
