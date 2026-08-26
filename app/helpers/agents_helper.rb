module AgentsHelper
  def may_need_onboarding_help?
    if defined?(current_territory)
      # Si un opérateur est rattaché au territoire et qu’il assure le support, c’est lui qui se charge de l’accompagnement
      # de ses adhérents.
      return false if current_territory.operator

      Rdv.joins(:organisation).where(organisation: { territory_id: current_territory.id }).limit(5).count < 5
    end
  end

  def needs_agent_search?
    current_organisation.agents.active.limit(10).count == 10 ||
      (current_organisation.agent_roles.basic.any? && current_organisation.agent_roles.admin.any?)
  end

  def current_agent?(agent)
    agent.id == current_agent.id
  end

  def me_tag(agent)
    tag.span("Vous", class: "fr-badge fr-badge--info fr-badge--no-icon fr-badge--sm") if current_agent?(agent)
  end

  def build_link_to_rdv_wizard_params(creneau, form)
    params = {}
    params[:step] = 2
    params[:starts_at] = creneau.starts_at
    params[:motif_id] = creneau.motif.id
    params[:lieu_id] = creneau.lieu&.id
    params[:organisation_id] = creneau.motif.organisation_id
    params[:duration_in_min] = creneau.motif.default_duration_in_min
    # Pour filtrer les agents depuis la recherche de créneaux coté agent
    params["agent_ids"] = [creneau.agent.id].compact
    params["user_ids"] = form.user_ids if form.user_ids.present?
    params["context"] = form.context if form.context.present?
    params
  end

  def agents_to_sentence(agents)
    agents.map(&:full_name_and_service).sort.to_sentence
  end

  def active_menu_item
    case controller_name
    when "lieux", "agents", "invitations", "motifs", "configurations", "organisations"
      :menu_settings
    when "rdvs_collectifs", "motif_selections"
      :menu_rdv_collectifs
    when "online_bookings"
      :menu_online_booking
    when "users", "merge_users", "referent_assignations"
      :menu_users
    when "rdvs"
      :menu_liste_rdvs
    end
  end

  def navigation_scoped_by_agent_services?(current_agent, current_organisation)
    return false if current_agent.agent_accueil_in_organisation?(current_organisation)

    !current_agent.admin_in_organisation?(current_organisation)
  end

  def organisations_grouped_by_territory_for_switcher
    current_agent.organisations.includes(:territory).ordered_by_name.group_by(&:territory)
  end
end
