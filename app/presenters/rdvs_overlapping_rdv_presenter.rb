class RdvsOverlappingRdvPresenter
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::TranslationHelper # allows getting a SafeBuffer instead of a String when using #translate (which a direct call to I18n.t doesn't do)

  attr_accessor :rdv, :agent, :agent_context, :rdv_context

  def initialize(rdv:, agent:, rdv_context:, agent_context:)
    @rdv = rdv
    @agent = agent
    @rdv_context = rdv_context
    @agent_context = agent_context
  end

  def warning_message
    translate("activemodel.warnings.models.rdv.attributes.base.#{i18n_key}", **i18n_attrs_base, **i18n_attrs_in_scope)
  end

  private

  def in_scope?
    @in_scope ||= Agent::RdvPolicy::Scope.new(agent_context, Rdv).in_scope?(rdv)
  end

  def i18n_key
    "rdvs_overlapping_rdv.#{i18n_suffix}"
  end

  def i18n_suffix
    if @agent == agent_context.agent
      "current_agent_html"
    elsif in_scope?
      "in_scope_html"
    else
      "out_of_scope_html"
    end
  end

  def i18n_attrs_base
    {
      agent_name: agent.full_name,
      ends_at_time: I18n.l(rdv.ends_at, format: :time_only),
    }
  end

  def i18n_attrs_in_scope
    return {} unless in_scope?

    { path: admin_organisation_rdv_path(rdv.organisation, rdv) }
  end
end
