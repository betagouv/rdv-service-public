class RdvEndingShortlyBeforePresenter
  include Rails.application.routes.url_helpers

  attr_accessor :rdv, :agent, :agent_context, :rdv_context

  def initialize(rdv:, agent:, rdv_context:, agent_context:)
    @rdv = rdv
    @agent = agent
    @rdv_context = rdv_context
    @agent_context = agent_context
  end

  def warning_message
    i18n_suffix = \
      if @agent == agent_context.agent
        "current_agent"
      elsif in_scope?
        "in_scope"
      else
        "out_of_scope"
      end
    i18n_key = "rdv_ending_shortly_before.#{i18n_suffix}"
    attrs = {
      agent_names: agent.full_name,
      ends_at_time: I18n.l(rdv.ends_at, format: :time_only),
      gap_duration_in_min: ((rdv_context.starts_at - rdv.ends_at) / 1.minute).round
    }
    if in_scope?
      attrs.merge!(
        user_names: rdv.users.map(&:full_name).to_sentence,
        path: admin_organisation_rdv_path(rdv.organisation, rdv)
      )
    end
    I18n.t("activemodel.warnings.models.rdv.attributes.base.#{i18n_key}", **attrs)
  end

  def in_scope?
    Agent::RdvPolicy::DepartementScope
      .new(agent_context, Rdv)
      .resolve
      .where(id: rdv.id)
      .any?
  end
end
