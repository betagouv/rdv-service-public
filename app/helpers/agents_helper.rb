module AgentsHelper
  def may_need_onboarding_help?
    if defined?(current_territory)
      Rdv.joins(:organisation).where(organisation: { territory_id: current_territory.id }).limit(5).count < 5
    end
  end

  def needs_agent_search?
    current_organisation.agents.active.limit(10).count == 10
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

  def menu_top_level_item
    {
      "menu-agendas" => "planning",
      "menu-plages-ouvertures" => "planning",
      "menu-absences" => "planning",
      "menu-settings" => "settings",
      "menu-organisation-stats" => "stats",
      "menu-stats" => "stats",
    }[content_for(:menu_item)]
  end


  def navigation_scoped_by_agent_services?(current_agent, current_organisation)
    return false if current_agent.secretaire?

    !current_agent.admin_in_organisation?(current_organisation)
  end

  def current_organisation_in_left_menu(&block)
    if current_agent.organisations_count > 1
      link_to(".left-submenu-account", "data-toggle" => :collapse, "aria-expanded" => "false", class: "side-menu__item", &block)
    else
      tag.div(class: "pt-2 pr-2 pb-2 pl-3", &block)
    end
  end
end
