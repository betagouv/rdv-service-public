module Admin::RdvFormConcern
  extend ActiveSupport::Concern
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TranslationHelper # allows getting a SafeBuffer instead of a String when using #translate (which a direct call to I18n.t doesn't do)
  include Rails.application.routes.url_helpers

  included do
    attr_accessor :rdv

    delegate(*::Rdv.hardcoded_attribute_names, to: :rdv)
    delegate :motif, :organisation, :agents, :users, to: :rdv
    delegate :overlapping_plages_ouvertures, :overlapping_plages_ouvertures?, to: :rdv
    delegate :overlapping_absences, :overlapping_absences?, to: :rdv
    delegate :rdvs_ending_shortly_before, :rdvs_ending_shortly_before?, to: :rdv_start_coherence
    delegate :rdvs_overlapping_rdv, :rdvs_overlapping_rdv?, to: :rdvs_overlapping

    delegate :errors, to: :rdv

    validate :check_duplicates

    delegate :ignore_benign_errors, :ignore_benign_errors=, :add_benign_error, :benign_errors, :not_benign_errors, :errors_are_all_benign?, to: :rdv
    validate :warn_overlapping_plage_ouverture
    validate :warn_overlapping_absence
    validate :warn_rdvs_ending_shortly_before
    validate :warn_rdvs_overlapping_rdv
    validate :warn_rdv_duplicate_suspected
    validate :warn_starts_in_the_past
    validate :warn_name_too_long_for_sms
  end

  def check_duplicates
    suspicious_rdvs = Rdv.includes(:users, :agents).where(
      organisation: rdv.organisation,
      lieu: rdv.lieu,
      starts_at: rdv.starts_at,
      ends_at: rdv.ends_at,
      motif: rdv.motif,
      status: Rdv::NOT_CANCELLED_STATUSES
    )
    suspicious_rdvs = suspicious_rdvs.where.not(id: rdv.id) if rdv.persisted?

    suspicious_rdvs = suspicious_rdvs.select do |existing_rdv|
      participants_of_existing_rdv = Set.new(existing_rdv.users + existing_rdv.agents)
      # Not using `rdv.users` because it does a db call, which returns an empty array because `rdv` is not persisted.
      # Using participations/agents_rdvs is safe because they are built from the nested attributes.
      participants_of_current_rdv = Set.new(rdv.participations.map(&:user) + rdv.agents_rdvs.map(&:agent))
      participants_of_existing_rdv == participants_of_current_rdv
    end
    errors.add(:base, :duplicate) if suspicious_rdvs.any?
  end

  private

  def warn_overlapping_plage_ouverture
    return if ignore_benign_errors

    return unless overlapping_plages_ouvertures?

    overlapping_plages_ouvertures
      .map { PlageOuverturePresenter.new(_1, agent_context) }
      .each { add_benign_error(_1.overlaps_rdv_error_message) }
  end

  def warn_overlapping_absence
    return if ignore_benign_errors

    return unless overlapping_absences?

    overlapping_absences.each do |absence|
      add_benign_error(
        translate(
          "activemodel.warnings.models.rdv.attributes.base.overlapping_absence",
          agent_name: absence.agent.full_name
        )
      )
    end
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

    rdv.participations.map(&:user).each do |user|
      suspicious_rdvs = Rdv
        .on_day(rdv.starts_at)
        .with_user(user)
        .where(motif: motif, status: Rdv::NOT_CANCELLED_STATUSES)
      suspicious_rdvs = suspicious_rdvs.where.not(id: rdv.id) if rdv.persisted?

      next unless suspicious_rdvs.any?

      user_path = admin_organisation_user_path(rdv.organisation, user)
      add_benign_error(translate("activemodel.warnings.models.rdv.attributes.base.rdv_duplicate_suspected_html", user_path: user_path, user_name: user.full_name))
    end
  end

  def warn_starts_in_the_past
    return if ignore_benign_errors
    return if rdv.starts_at >= Time.zone.now

    add_benign_error(I18n.t("activemodel.warnings.models.rdv.attributes.starts_at.in_the_past", distance: distance_of_time_in_words_to_now(rdv.starts_at)))
  end

  def warn_name_too_long_for_sms
    return if ignore_benign_errors
    return if rdv.individuel?

    truncated_name = Users::RdvSms.truncated_rdv_name(rdv.name)

    return if truncated_name == rdv.name

    add_benign_error("L'intitulé est trop long et sera abrégé ainsi dans les notifications SMS : #{truncated_name}")
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
