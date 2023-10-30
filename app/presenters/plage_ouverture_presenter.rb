class PlageOuverturePresenter
  include PlageOuverturesHelper
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::TranslationHelper # allows getting a SafeBuffer instead of a String when using #translate (which a direct call to I18n.t doesn't do)

  attr_accessor :plage_ouverture, :agent_context

  def initialize(plage_ouverture, agent_context)
    @plage_ouverture = plage_ouverture
    @agent_context = agent_context
  end

  def overlaps_rdv_error_message
    i18n_key = [
      "overlapping_plage_ouverture",
      (in_scope? ? "in_scope" : "out_of_scope"),
      (same_organisation? ? "in_current_organisation_html" : "in_other_organisation_html"),
    ].join(".")
    attrs = { agent_name: plage_ouverture.agent.full_name }
    if in_scope?
      attrs.merge!(
        path: admin_organisation_plage_ouverture_path(plage_ouverture.organisation, plage_ouverture),
        lieu_name: plage_ouverture.lieu_name,
        occurrence_text: plage_ouverture_occurrence_text(plage_ouverture),
        organisation_name: plage_ouverture.organisation.name
      )
    end
    translate("activemodel.warnings.models.rdv.attributes.base.#{i18n_key}", **attrs)
  end

  def same_organisation?
    plage_ouverture.organisation == agent_context.organisation
  end

  def in_scope?
    Agent::PlageOuverturePolicy::DepartementScope
      .new(agent_context, PlageOuverture)
      .resolve
      .where(id: plage_ouverture.id)
      .any?
  end
end
