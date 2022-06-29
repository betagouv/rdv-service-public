# frozen_string_literal: true

module Admin::RdvFormConcern
  extend ActiveSupport::Concern

  included do
    attr_accessor :rdv

    delegate(*::Rdv.attribute_names, to: :rdv)
    delegate :motif, :organisation, :agents, :users, to: :rdv
    delegate :overlapping_plages_ouvertures, :overlapping_plages_ouvertures?, to: :rdv
    delegate :rdvs_ending_shortly_before, :rdvs_ending_shortly_before?, to: :rdv_start_coherence
    delegate :rdvs_overlapping_rdv, :rdvs_overlapping_rdv?, to: :rdvs_overlapping

    delegate :errors, to: :rdv

    validate :validate_rdv

    delegate :ignore_benign_errors, :ignore_benign_errors=, :add_benign_error, :benign_errors, :not_benign_errors, :errors_are_all_benign?, to: :rdv
    validate :warn_overlapping_plage_ouverture
    validate :warn_rdvs_ending_shortly_before
    validate :warn_rdvs_overlapping_rdv
    validate :warn_rdv_duplicate_suspected
  end

  private

  def validate_rdv
    rdv.validate
  end

  def warn_overlapping_plage_ouverture
    return if ignore_benign_errors

    return unless overlapping_plages_ouvertures?

    overlapping_plages_ouvertures
      .map { PlageOuverturePresenter.new(_1, agent_context) }
      .each { add_benign_error(_1.overlaps_rdv_error_message) }
  end

  def warn_rdvs_ending_shortly_before
    return if ignore_benign_errors

    return unless rdvs_ending_shortly_before?

    rdv_agent_pairs_ending_shortly_before_grouped_by_agent.values.map do |pair|
      RdvEndingShortlyBeforePresenter.new(
        rdv: pair.rdv,
        agent: pair.agent,
        rdv_context: rdv,
        agent_context: agent_context
      )
    end.each { add_benign_error(_1.warning_message) }
  end

  def warn_rdvs_overlapping_rdv
    return if ignore_benign_errors

    return unless rdvs_overlapping_rdv?

    rdv_agent_pairs_rdvs_overlapping_grouped_by_agent.values.map do |pair|
      RdvsOverlappingRdvPresenter.new(
        rdv: pair.rdv,
        agent: pair.agent,
        rdv_context: rdv,
        agent_context: agent_context
      )
    end.each { add_benign_error(_1.warning_message) }
  end

  def warn_rdv_duplicate_suspected
    return if ignore_benign_errors

    rdv.users.each do |user|
      suspicious_rdvs = Rdv
        .on_day(rdv.starts_at)
        .with_user(user)
        .where(motif: motif)
        .to_a

      if suspicious_rdvs.any?
        user_path = admin_organisation_user_path(rdv.organisation, user)
        add_benign_error(I18n.t("activemodel.warnings.models.rdv.attributes.base.rdv_duplicate_suspected", user_path: user_path, user_name: user.full_name))
      end
    end
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
